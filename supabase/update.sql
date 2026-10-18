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

-- v3: "paused" and "did not finish". Adding enum values never touches the
-- rows that already use the old ones.
alter type public.reading_status add value if not exists 'paused' before 'read';
alter type public.reading_status add value if not exists 'abandoned' before 'read';

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

-- v3: earlier reads of books read more than once, as
-- [{"started_at": "2021-03-01", "finished_at": "2021-03-20"}, ...].
-- Existing books start with an empty history.
alter table public.user_books
  add column if not exists past_reads jsonb not null default '[]'::jsonb
    check (jsonb_typeof(past_reads) = 'array');

-- v4: format (audiobooks in minutes), saga, moods and pace, loans.
-- Every column is nullable or has a default: existing books keep their
-- values and simply start as "paper", with no saga, moods or loan.
alter table public.user_books
  add column if not exists format text not null default 'paper'
    check (format in ('paper', 'ebook', 'audio'));
alter table public.user_books
  add column if not exists duration_minutes integer
    check (duration_minutes is null or duration_minutes > 0);
alter table public.user_books
  add column if not exists series_name text
    check (series_name is null or char_length(series_name) between 1 and 80);
alter table public.user_books
  add column if not exists series_index numeric(6, 1)
    check (series_index is null or series_index > 0);
alter table public.user_books
  add column if not exists series_total integer
    check (series_total is null or series_total > 0);
alter table public.user_books
  add column if not exists moods text[] not null default '{}';
alter table public.user_books
  add column if not exists pace text
    check (pace is null or pace in ('slow', 'medium', 'fast'));
alter table public.user_books
  add column if not exists loan_kind text
    check (loan_kind is null or loan_kind in ('lent', 'borrowed'));
alter table public.user_books
  add column if not exists loan_person text
    check (loan_person is null or char_length(loan_person) between 1 and 80);
alter table public.user_books
  add column if not exists loan_since date;
alter table public.user_books
  add column if not exists loan_due date;

-- v5: one book can hold several volumes of a saga (e.g. volumes 1-2 of
-- 1Q84 in one book): the last one it holds. Null for a single volume.
alter table public.user_books
  add column if not exists series_index_end numeric(6, 1)
    check (series_index_end is null or series_index_end > 0);

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.user_books'::regclass
      and conname = 'user_books_series_range_check'
  ) then
    alter table public.user_books
      add constraint user_books_series_range_check
      check (series_index_end is null or series_index is null
             or series_index_end >= series_index);
  end if;
end
$$;

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

-- v3: quotes saved from a book
create table if not exists public.book_quotes (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default auth.uid()
                 references auth.users (id) on delete cascade,
  user_book_id uuid not null
                 references public.user_books (id) on delete cascade,
  text         text not null check (char_length(text) between 1 and 2000),
  page         integer check (page is null or page > 0),
  created_at   timestamptz not null default now()
);

create index if not exists book_quotes_book_idx
  on public.book_quotes (user_book_id, created_at desc);

alter table public.book_quotes enable row level security;

-- v7: shared shelves. One link (token) per custom shelf; anyone with the
-- token reads the shelf through get_shared_shelf(), never the table.
create table if not exists public.shelf_shares (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid()
               references auth.users (id) on delete cascade,
  shelf_name text not null
               check (char_length(btrim(shelf_name)) between 1 and 30),
  token      text not null unique
               default substr(translate(encode(extensions.gen_random_bytes(16),
                                               'base64'), '+/=', '-_'), 1, 22),
  created_at timestamptz not null default now()
);

create unique index if not exists shelf_shares_user_shelf_unique
  on public.shelf_shares (user_id, lower(shelf_name));

alter table public.shelf_shares enable row level security;

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
      ('book_quotes',  'book_quotes_select_own',  'select'),
      ('book_quotes',  'book_quotes_insert_own',  'insert'),
      ('book_quotes',  'book_quotes_update_own',  'update'),
      ('book_quotes',  'book_quotes_delete_own',  'delete'),
      ('shelf_shares', 'shelf_shares_select_own', 'select'),
      ('shelf_shares', 'shelf_shares_insert_own', 'insert'),
      ('shelf_shares', 'shelf_shares_delete_own', 'delete'),
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

-- ---------------------------------------------------------------------------
-- profiles: created on sign-up (email, Apple)
-- ---------------------------------------------------------------------------
-- v6: Sign in with Apple. The profile created at sign-up takes the name
-- Apple shares. Replacing the function leaves existing rows
-- untouched; the trigger is only created when missing.
--
-- display_name comes from the `data` passed to auth.signUp or, for Sign in
-- with Apple, from the name Apple shares, falling back to the local part of
-- the email.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''),
      nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
      nullif(trim(new.raw_user_meta_data ->> 'name'), ''),
      split_part(new.email, '@', 1)
    )
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

do $$
begin
  if not exists (
    select 1 from pg_trigger
    where tgname = 'on_auth_user_created'
      and tgrelid = 'auth.users'::regclass
  ) then
    create trigger on_auth_user_created
      after insert on auth.users
      for each row execute function public.handle_new_user();
  end if;
end
$$;

-- v7: public read of a shared shelf: only the shelf name, the owner's display
-- name and title/authors/cover/year of its books. Null for an unknown token.
create or replace function public.get_shared_shelf(p_token text)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'shelf_name', s.shelf_name,
    'owner_name', p.display_name,
    'books', coalesce((
      select jsonb_agg(jsonb_build_object(
               'external_id', b.external_id,
               'title', b.title,
               'authors', b.authors,
               'cover_url', b.cover_url,
               'published_year', b.published_year)
             order by b.created_at)
      from public.user_books b
      where b.user_id = s.user_id
        and exists (select 1 from unnest(b.shelves) t(name)
                    where lower(t.name) = lower(s.shelf_name))
    ), '[]'::jsonb))
  from public.shelf_shares s
  left join public.profiles p on p.id = s.user_id
  where s.token = p_token;
$$;

revoke all on function public.get_shared_shelf(text) from public;
grant execute on function public.get_shared_shelf(text) to anon, authenticated;

-- Make sure the API sees the new columns and tables right away.
notify pgrst, 'reload schema';

-- ---------------------------------------------------------------------------
-- Report: what the database contains now. Look for:
--   * every column listed above under user_books (shelves, edition_key,
--     past_reads, format, series_name, series_index_end, moods, pace,
--     loan_kind, ...)
--   * the tables reading_logs, book_quotes and shelf_shares
--   * 4 policies each on user_books, reading_logs and book_quotes, 3 on
--     shelf_shares
--   * the function get_shared_shelf
--   * the reading_status values, "paused" and "abandoned" included
--   * any trigger or constraint you do not recognise
-- ---------------------------------------------------------------------------
select 'column' as kind, column_name::text as name, data_type::text as detail
from information_schema.columns
where table_schema = 'public' and table_name = 'user_books'
union all
select 'table', table_name::text, ''
from information_schema.tables
where table_schema = 'public'
  and table_name in ('reading_logs', 'book_quotes', 'shelf_shares')
union all
select 'function', routine_name::text, security_type::text
from information_schema.routines
where routine_schema = 'public' and routine_name = 'get_shared_shelf'
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
where schemaname = 'public'
  and tablename in ('user_books', 'reading_logs', 'book_quotes', 'shelf_shares')
union all
select 'enum value', enumlabel::text, 'sort order ' || enumsortorder::text
from pg_enum
where enumtypid = 'public.reading_status'::regtype
order by 1, 2;
