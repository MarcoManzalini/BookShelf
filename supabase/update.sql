-- =============================================================================
-- BookShelf - Supabase UPDATE script
--
-- Brings an EXISTING database up to what the app expects. Run it as many
-- times as you like: it only ADDS what is missing.
--
--   * never drops or truncates a table, never deletes or rewrites a row
--   * columns: "add column if not exists" (existing values are untouched)
--   * tables / indexes: "create ... if not exists"
--   * policies: created only when missing (existing ones are left alone)
--   * at the end, one result table shows what the database really contains
--
-- Paste it in: Supabase Dashboard -> SQL Editor -> New query -> Run.
-- For a brand-new project use schema.sql instead.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Enum (only if the project never had it)
-- ---------------------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_type where typname = 'reading_status') then
    create type public.reading_status as enum ('want_to_read', 'reading', 'read');
  end if;
end
$$;

-- ---------------------------------------------------------------------------
-- user_books: every column the app reads or writes
-- ---------------------------------------------------------------------------
alter table public.user_books add column if not exists authors        text[] not null default '{}';
alter table public.user_books add column if not exists cover_url      text;
alter table public.user_books add column if not exists description    text;
alter table public.user_books add column if not exists isbn           text;
alter table public.user_books add column if not exists page_count     integer;
alter table public.user_books add column if not exists publisher      text;
alter table public.user_books add column if not exists published_year integer;
alter table public.user_books add column if not exists subjects       text[] not null default '{}';
alter table public.user_books add column if not exists language       text;
alter table public.user_books add column if not exists current_page   integer not null default 0;
alter table public.user_books add column if not exists rating         smallint;
alter table public.user_books add column if not exists notes          text;
alter table public.user_books add column if not exists started_at     date;
alter table public.user_books add column if not exists finished_at    date;
alter table public.user_books add column if not exists updated_at     timestamptz not null default now();

-- v2: custom shelves and the chosen edition
alter table public.user_books add column if not exists shelves        text[] not null default '{}';
alter table public.user_books add column if not exists edition_key    text;

-- Keeps updated_at current (only created when missing).
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

do $$
begin
  if not exists (
    select 1 from pg_trigger
    where tgrelid = 'public.user_books'::regclass
      and tgname = 'user_books_set_updated_at'
  ) then
    create trigger user_books_set_updated_at
      before update on public.user_books
      for each row execute function public.set_updated_at();
  end if;
end
$$;

-- ---------------------------------------------------------------------------
-- profiles: yearly reading goal
-- ---------------------------------------------------------------------------
alter table public.profiles
  add column if not exists reading_goal integer
    check (reading_goal is null or reading_goal between 1 and 1000);

-- ---------------------------------------------------------------------------
-- reading_logs: history of reading sessions (pages / minutes per day)
-- ---------------------------------------------------------------------------
create table if not exists public.reading_logs (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default auth.uid()
                 references auth.users (id) on delete cascade,
  user_book_id uuid not null
                 references public.user_books (id) on delete cascade,
  logged_on    date not null default current_date,
  pages        integer not null default 0 check (pages >= 0),
  minutes      integer check (minutes is null or minutes > 0),
  end_page     integer check (end_page is null or end_page >= 0),
  created_at   timestamptz not null default now()
);

create index if not exists reading_logs_user_day_idx
  on public.reading_logs (user_id, logged_on);
create index if not exists reading_logs_book_idx
  on public.reading_logs (user_book_id);

alter table public.reading_logs enable row level security;

-- Policies are created only when missing, so any change you made by hand to
-- an existing policy is kept.
do $$
declare
  p record;
begin
  for p in
    select * from (values
      ('reading_logs', 'reading_logs_select_own', 'select'),
      ('reading_logs', 'reading_logs_insert_own', 'insert'),
      ('reading_logs', 'reading_logs_update_own', 'update'),
      ('reading_logs', 'reading_logs_delete_own', 'delete'),
      ('user_books',   'user_books_select_own',   'select'),
      ('user_books',   'user_books_insert_own',   'insert'),
      ('user_books',   'user_books_update_own',   'update'),
      ('user_books',   'user_books_delete_own',   'delete')
    ) as t (tbl, name, cmd)
  loop
    if exists (
      select 1 from pg_policies
      where schemaname = 'public' and tablename = p.tbl and policyname = p.name
    ) then
      continue;
    end if;

    if p.cmd = 'select' or p.cmd = 'delete' then
      execute format(
        'create policy %I on public.%I for %s to authenticated '
        'using ((select auth.uid()) = user_id)',
        p.name, p.tbl, p.cmd
      );
    elsif p.cmd = 'insert' then
      execute format(
        'create policy %I on public.%I for insert to authenticated '
        'with check ((select auth.uid()) = user_id)',
        p.name, p.tbl
      );
    else
      execute format(
        'create policy %I on public.%I for update to authenticated '
        'using ((select auth.uid()) = user_id) '
        'with check ((select auth.uid()) = user_id)',
        p.name, p.tbl
      );
    end if;
  end loop;
end
$$;

-- Make sure the API sees the new columns and tables right away.
notify pgrst, 'reload schema';

-- ---------------------------------------------------------------------------
-- Report: what the database contains now. Look for:
--   * every column listed above under user_books (shelves, edition_key, ...)
--   * the table reading_logs
--   * 4 policies each on user_books and reading_logs
--   * any trigger or constraint you do not recognise
-- ---------------------------------------------------------------------------
select 'column' as kind, column_name::text as name, data_type::text as detail
from information_schema.columns
where table_schema = 'public' and table_name = 'user_books'
union all
select 'table', table_name::text, ''
from information_schema.tables
where table_schema = 'public' and table_name = 'reading_logs'
union all
select 'trigger', tgname::text, pg_get_triggerdef(oid)
from pg_trigger
where tgrelid = 'public.user_books'::regclass and not tgisinternal
union all
select 'constraint', conname::text, pg_get_constraintdef(oid)
from pg_constraint
where conrelid = 'public.user_books'::regclass
union all
select 'policy', tablename::text || '.' || policyname::text, cmd::text
from pg_policies
where schemaname = 'public' and tablename in ('user_books', 'reading_logs')
order by 1, 2;
