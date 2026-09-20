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
-- display_name comes from the `data` passed to auth.signUp, falling back to
-- the local part of the email.
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
