-- =============================================================================
-- BookShelf - Supabase schema
-- Paste this whole file into: Supabase Dashboard -> SQL Editor -> New query -> Run
-- Safe to re-run: objects are created idempotently where possible.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Enum
-- ---------------------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_type where typname = 'reading_status') then
    create type public.reading_status as enum ('want_to_read', 'reading', 'read');
  end if;
end
$$;

-- ---------------------------------------------------------------------------
-- Generic updated_at trigger function
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  avatar_url   text,
  created_at   timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles
  for select to authenticated
  using ((select auth.uid()) = id);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own" on public.profiles
  for insert to authenticated
  with check ((select auth.uid()) = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles
  for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

drop policy if exists "profiles_delete_own" on public.profiles;
create policy "profiles_delete_own" on public.profiles
  for delete to authenticated
  using ((select auth.uid()) = id);

-- Creates the profile row automatically when a user signs up.
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

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Backfill profiles for users created before this script was run.
insert into public.profiles (id, display_name)
select u.id, split_part(u.email, '@', 1)
from auth.users u
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- user_books
-- ---------------------------------------------------------------------------
create table if not exists public.user_books (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null default auth.uid()
                   references auth.users (id) on delete cascade,
  external_id    text not null,                       -- Open Library work id, e.g. OL45804W
  title          text not null,
  authors        text[] not null default '{}',
  cover_url      text,
  description    text,
  isbn           text,
  page_count     integer check (page_count is null or page_count > 0),
  publisher      text,
  published_year integer,
  subjects       text[] not null default '{}',
  language       text,
  status         public.reading_status not null default 'want_to_read',
  current_page   integer not null default 0 check (current_page >= 0),
  rating         smallint check (rating is null or rating between 1 and 5),
  notes          text,
  started_at     date,
  finished_at    date,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  constraint user_books_user_external_unique unique (user_id, external_id)
);

create index if not exists user_books_user_status_idx
  on public.user_books (user_id, status);

drop trigger if exists user_books_set_updated_at on public.user_books;
create trigger user_books_set_updated_at
  before update on public.user_books
  for each row execute function public.set_updated_at();

alter table public.user_books enable row level security;

drop policy if exists "user_books_select_own" on public.user_books;
create policy "user_books_select_own" on public.user_books
  for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "user_books_insert_own" on public.user_books;
create policy "user_books_insert_own" on public.user_books
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "user_books_update_own" on public.user_books;
create policy "user_books_update_own" on public.user_books
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "user_books_delete_own" on public.user_books;
create policy "user_books_delete_own" on public.user_books
  for delete to authenticated
  using ((select auth.uid()) = user_id);

-- ---------------------------------------------------------------------------
-- v2 additions (custom shelves, editions, reading goal, reading log)
-- Idempotent: safe to run on a database that already has the tables above.
-- ---------------------------------------------------------------------------
alter table public.user_books
  add column if not exists shelves text[] not null default '{}';   -- custom shelves (tags)
alter table public.user_books
  add column if not exists edition_key text;                       -- chosen Open Library edition, e.g. OL123M

alter table public.profiles
  add column if not exists reading_goal integer
    check (reading_goal is null or reading_goal between 1 and 1000); -- books per year

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

drop policy if exists "reading_logs_select_own" on public.reading_logs;
create policy "reading_logs_select_own" on public.reading_logs
  for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "reading_logs_insert_own" on public.reading_logs;
create policy "reading_logs_insert_own" on public.reading_logs
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "reading_logs_update_own" on public.reading_logs;
create policy "reading_logs_update_own" on public.reading_logs
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "reading_logs_delete_own" on public.reading_logs;
create policy "reading_logs_delete_own" on public.reading_logs
  for delete to authenticated
  using ((select auth.uid()) = user_id);

-- ---------------------------------------------------------------------------
-- v3 additions (paused / did-not-finish, re-reads, quotes)
-- Idempotent: safe to run on a database that already has the tables above.
-- ---------------------------------------------------------------------------
-- v3: "paused" and "did not finish". Adding enum values never touches the
-- rows that already use the old ones.
alter type public.reading_status add value if not exists 'paused' before 'read';
alter type public.reading_status add value if not exists 'abandoned' before 'read';

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

drop policy if exists "book_quotes_select_own" on public.book_quotes;
create policy "book_quotes_select_own" on public.book_quotes
  for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "book_quotes_insert_own" on public.book_quotes;
create policy "book_quotes_insert_own" on public.book_quotes
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "book_quotes_update_own" on public.book_quotes;
create policy "book_quotes_update_own" on public.book_quotes
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "book_quotes_delete_own" on public.book_quotes;
create policy "book_quotes_delete_own" on public.book_quotes
  for delete to authenticated
  using ((select auth.uid()) = user_id);

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

drop policy if exists "shelf_shares_select_own" on public.shelf_shares;
create policy "shelf_shares_select_own" on public.shelf_shares
  for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "shelf_shares_insert_own" on public.shelf_shares;
create policy "shelf_shares_insert_own" on public.shelf_shares
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "shelf_shares_delete_own" on public.shelf_shares;
create policy "shelf_shares_delete_own" on public.shelf_shares
  for delete to authenticated
  using ((select auth.uid()) = user_id);

-- Public read of a shared shelf: only the shelf name, the owner's display
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

-- ---------------------------------------------------------------------------
-- Storage: avatars bucket
-- Files live under "<user_id>/<file>". The bucket is public so avatar URLs can
-- be shown without signed URLs; writes are restricted to the owner's folder.
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'avatars',
  'avatars',
  true,
  2097152, -- 2 MB
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "avatars_public_read" on storage.objects;
create policy "avatars_public_read" on storage.objects
  for select
  using (bucket_id = 'avatars');

drop policy if exists "avatars_insert_own_folder" on storage.objects;
create policy "avatars_insert_own_folder" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "avatars_update_own_folder" on storage.objects;
create policy "avatars_update_own_folder" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "avatars_delete_own_folder" on storage.objects;
create policy "avatars_delete_own_folder" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- ---------------------------------------------------------------------------
-- Account deletion
-- The client cannot delete its own auth.users row, so it calls this RPC
-- (supabase.rpc('delete_my_account')). ON DELETE CASCADE removes the profile
-- and all user_books rows. Avatar files are removed by the client beforehand
-- (Supabase does not allow deleting storage rows from SQL).
-- No Edge Function is required.
-- ---------------------------------------------------------------------------
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;
  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
