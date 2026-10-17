# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

BookShelf is a Flutter app (Android + iOS only; web/desktop targets exist but are unsupported) for tracking reading, backed by Supabase (auth, Postgres with RLS, `avatars` storage) and Open Library for book data. UI and README are in Italian; Italian is the default locale.

## Commands

```bash
flutter pub get                       # also regenerates lib/l10n/gen/
flutter run
flutter analyze
flutter test                          # all tests
flutter test test/features/library    # one directory
flutter test test/core/isbn_test.dart # one file
flutter test --plain-name "substring of test name" test/path_test.dart
flutter gen-l10n                      # after editing .arb files
dart format <files>
```

No `build_runner`: models are hand-written `Equatable` classes. Never edit `lib/l10n/gen/` by hand.

Requires a `.env` (copy `.env.example`, set `SUPABASE_URL`, `SUPABASE_ANON_KEY`). It is bundled as a Flutter asset; if missing, `main.dart` shows a "missing configuration" screen instead of crashing.

## Lint rules worth knowing

`analysis_options.yaml` enables `strict-casts`, `strict-raw-types`, `require_trailing_commas`, `prefer_single_quotes`, `prefer_final_locals`, `unawaited_futures`, `avoid_print`, `always_declare_return_types`. Code must pass `flutter analyze` cleanly.

## Architecture

Feature-first under `lib/features/<feature>/` with `data` (datasources, mappers, repository impls), `domain` (entities, abstract repositories, use cases) and `presentation` (bloc/cubit, pages, widgets). Pages depend only on Blocs; Blocs depend only on abstract repositories. Some small features (`home_widget`, `scanner`, `recap`) omit layers.

- **DI**: everything is wired in `lib/core/di/injection.dart` (`getIt`). Datasources/repositories/services are `registerLazySingleton`; page-scoped Blocs/Cubits are `registerFactory` (or `registerFactoryParam`). New datasources, repositories, and Blocs must be registered there.
- **App-wide Blocs**: `AuthBloc`, `LibraryBloc`, `ThemeCubit` are singletons provided in `lib/app.dart`. `app.dart` also reacts to auth changes (start/clear library, reminders, home widget) and refreshes on app resume.
- **Routing**: `lib/core/router/app_router.dart` (go_router) with auth redirect guard driven by `AuthBloc` via `go_router_refresh_stream.dart`; bottom-nav shell in `main_shell.dart`.
- **Errors**: repositories catch every exception and rethrow `Failure(FailureCode)` via `mapError` in `core/errors/error_mapper.dart` (Dio / Supabase / network → code). UI turns codes into localized text in `failure_message.dart`. Postgres "undefined column/table" codes (`42703`, `PGRST204`, `PGRST205`) map to `FailureCode.outdatedDatabase`, which tells the user to run `update.sql`. State classes use `RequestStatus` (`initial/loading/success/failure`) from `core/utils`.
- **Library / offline**: `LibraryRepositoryImpl` keeps an in-memory + on-file cache (`library/data/local/library_cache.dart`), exposes a `Stream` of changes that `LibraryBloc` follows (so edits in details show everywhere), and queues offline writes to sync when the network returns.
- **Book details**: `BookDetailsBloc` handles both library books and search-result previews; edits are optimistic with rollback. Domain rules (status transitions, rereads, audiobooks, multi-volume series, loans) live in `UserBook` and related entities in `library/domain/entities/`, not in Blocs.
- **Notifications**: local only (`reminders/`), behind the `ReminderScheduler` abstraction (faked in tests). Reminders are recomputed on app open and after logging a session.
- **Home widget**: `home_widget/` computes data for the Android widget (`ReadingWidgetProvider.kt`). iOS widget in `ios/ReadingWidget/` is not linked to the project.
- **Open Library**: requests go through the shared `Dio` with `AppConfig.userAgent`. Config flags such as `AppConfig.socialLoginEnabled` live in `core/config/app_config.dart`.

## Localization

`lib/l10n/app_it.arb` is the template; `app_en.arb` must have the same keys and placeholders. Access strings via the extension in `core/utils/l10n_extension.dart` / `AppLocalizations.of(context)`.

## Database (Supabase)

SQL is maintained by hand and pasted into the Supabase SQL Editor; there are no CLI migrations.

- `supabase/schema.sql`: full schema for a new project (tables `profiles`, `user_books`, `reading_logs`, `book_quotes`, RLS, triggers incl. `handle_new_user`, `avatars` bucket, `delete_my_account()` security definer function).
- `supabase/update.sql`: idempotent upgrade for existing databases. It only adds: `add column if not exists`, `create ... if not exists`, enum values via `add value if not exists`, policies only when missing. Never drops, truncates or rewrites rows. It ends with a verification query.

Any schema change must be applied to **both** files, keeping `update.sql` idempotent and non-destructive, and every new table needs RLS scoped to `auth.uid()`.

## Tests

`test/helpers/` has `pump_app.dart` (`tester.pumpApp(widget)` wraps in a localized, themed `MaterialApp`, Italian by default), `mocks.dart` (mocktail mocks) and `fixtures.dart`. Blocs are tested with `bloc_test`. Tests mirror `lib/` structure under `test/features/`, `test/core/`, plus widget tests in `test/widget/`.
