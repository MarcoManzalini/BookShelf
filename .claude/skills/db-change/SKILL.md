---
name: db-change
description: Apply a Supabase schema change (new column, table, enum value, policy, function) to both supabase/schema.sql and supabase/update.sql, keeping update.sql idempotent and non-destructive.
disable-model-invocation: true
argument-hint: <description of the schema change>
---

# Database change: $ARGUMENTS

There are no CLI migrations. The user pastes SQL into the Supabase SQL Editor, so both files must be correct on their own.

## 1. `supabase/schema.sql` (new projects)

Add the change to the definition itself (column inside `create table`, new table with its indexes, RLS and policies, enum value in `create type`). The file must still run cleanly on an empty project and be re-runnable.

## 2. `supabase/update.sql` (existing databases)

Add a section, labelled with the app version / feature, before the final verification query. Rules:

- Columns: `alter table ... add column if not exists ...` — defaults must not rewrite existing meaning.
- Tables / indexes: `create table if not exists`, `create index if not exists`.
- Enum values: `alter type ... add value if not exists ...`.
- Policies: create only when missing (`do $$ ... if not exists (select 1 from pg_policies where ...) ... $$`), following the existing pattern in the file.
- Functions / triggers: `create or replace`.
- **Never** `drop`, `truncate`, `delete`, or `update` that rewrites user rows.
- Update the final verification query if it lists columns/tables that changed.

## 3. Security

Every new table: `enable row level security` plus select/insert/update/delete policies scoped to `auth.uid() = user_id` (or the ownership path through a parent table). `security definer` functions must `set search_path = ''` and check `auth.uid()`.

## 4. App side

- Mapper in `lib/features/<feature>/data/mappers/` and the entity (hand-written `Equatable`, add to `props`).
- Remote datasource select lists, if they name columns explicitly.
- A missing column surfaces as `FailureCode.outdatedDatabase` (`core/errors/error_mapper.dart`), so old databases get a clear message — no extra handling needed.
- Tests for the mapper / repository.

## 5. Finish

Run `flutter analyze` and `flutter test`. Tell the user to run `update.sql` on their database (or use the Supabase MCP only for read-only verification).
