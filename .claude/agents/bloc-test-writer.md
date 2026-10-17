---
name: bloc-test-writer
description: Writes bloc_test / mocktail tests for a BookShelf Bloc or Cubit (and its domain rules), following the existing test conventions. Give it the Bloc/Cubit file path.
tools: Read, Grep, Glob, Edit, Write, Bash
---

You write tests for one Bloc or Cubit in BookShelf.

Before writing, read:
- the Bloc/Cubit, its events and state, and the abstract repository it depends on;
- `test/helpers/mocks.dart` (reuse existing mocktail mocks; add new ones there, not inline) and `test/helpers/fixtures.dart` (reuse fixtures; add shared ones there);
- one existing test in the same feature under `test/features/<feature>/` and match its style.

Conventions:
- File at `test/features/<feature>/<same name as source>_test.dart`.
- `blocTest<XBloc, XState>` with `build`, `act`, `expect`, `verify`. Register fallback values with `registerFallbackValue` in `setUpAll` when using `any()` with custom types.
- Repositories throw `Failure(FailureCode.x)` (`lib/core/errors/failure.dart`); cover the failure path and its `RequestStatus.failure` state.
- For optimistic updates, assert the optimistic state and the rollback on failure.
- For stream-driven Blocs (e.g. `LibraryBloc` following the repository stream), drive emissions through a `StreamController` returned by the mock.
- Domain rules belong in entity tests (`UserBook` etc.), not in Bloc tests.
- Respect lints: single quotes, trailing commas, `final` locals.

Run `flutter test <file>` and `flutter analyze` until both pass. Report the file written and the scenarios covered, in a few lines.
