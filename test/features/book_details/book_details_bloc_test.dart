import 'package:bloc_test/bloc_test.dart';
import 'package:bookshelf/core/errors/failure.dart';
import 'package:bookshelf/core/utils/request_status.dart';
import 'package:bookshelf/features/book_details/presentation/bloc/book_details_bloc.dart';
import 'package:bookshelf/features/library/domain/entities/reading_status.dart';
import 'package:bookshelf/features/library/domain/entities/user_book.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockLibraryRepository library;
  late MockBookSearchRepository search;
  late MockAddBookToLibrary addBook;

  final book = buildBook();
  final saved = buildUserBook(book: book);

  setUpAll(() {
    registerFallbackValue(buildUserBook());
    registerFallbackValue(buildBook());
    registerFallbackValue(ReadingStatus.read);
  });

  setUp(() {
    library = MockLibraryRepository();
    search = MockBookSearchRepository();
    addBook = MockAddBookToLibrary();
  });

  BookDetailsBloc build() => BookDetailsBloc(
        libraryRepository: library,
        searchRepository: search,
        addBook: addBook,
      );

  BookDetailsState libraryState(UserBook userBook) => BookDetailsState(
        status: RequestStatus.success,
        book: userBook.book,
        userBook: userBook,
      );

  group('library mode', () {
    blocTest<BookDetailsBloc, BookDetailsState>(
      'loads a saved book',
      setUp: () =>
          when(() => library.getById('ub-1')).thenAnswer((_) async => saved),
      build: build,
      act: (bloc) => bloc.add(const BookDetailsLibraryRequested('ub-1')),
      expect: () => [
        const BookDetailsState(status: RequestStatus.loading),
        libraryState(saved),
      ],
    );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'fails with notFound when the book does not exist',
      setUp: () =>
          when(() => library.getById(any())).thenAnswer((_) async => null),
      build: build,
      act: (bloc) => bloc.add(const BookDetailsLibraryRequested('nope')),
      expect: () => const [
        BookDetailsState(status: RequestStatus.loading),
        BookDetailsState(
          status: RequestStatus.failure,
          failure: Failure(FailureCode.notFound),
        ),
      ],
    );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'fails on repository error',
      setUp: () => when(() => library.getById(any()))
          .thenThrow(const Failure(FailureCode.network)),
      build: build,
      act: (bloc) => bloc.add(const BookDetailsLibraryRequested('ub-1')),
      expect: () => const [
        BookDetailsState(status: RequestStatus.loading),
        BookDetailsState(
          status: RequestStatus.failure,
          failure: Failure(FailureCode.network),
        ),
      ],
    );
  });

  group('preview mode', () {
    blocTest<BookDetailsBloc, BookDetailsState>(
      'shows the book, then enriches it with work details',
      setUp: () {
        when(() => library.findCachedByExternalId(any())).thenReturn(null);
        when(() => search.getBookDetails(book))
            .thenAnswer((_) async => book.copyWith(description: 'Spice.'));
      },
      build: build,
      act: (bloc) => bloc.add(BookDetailsPreviewRequested(book)),
      expect: () => [
        BookDetailsState(status: RequestStatus.success, book: book),
        BookDetailsState(
          status: RequestStatus.success,
          book: book.copyWith(description: 'Spice.'),
        ),
      ],
    );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'keeps the basic preview when the details lookup fails',
      setUp: () {
        when(() => library.findCachedByExternalId(any())).thenReturn(null);
        when(() => search.getBookDetails(any()))
            .thenThrow(const Failure(FailureCode.network));
      },
      build: build,
      act: (bloc) => bloc.add(BookDetailsPreviewRequested(book)),
      expect: () => [
        BookDetailsState(status: RequestStatus.success, book: book),
      ],
    );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'opens in library mode when the book is already saved',
      setUp: () =>
          when(() => library.findCachedByExternalId('OL1W')).thenReturn(saved),
      build: build,
      act: (bloc) => bloc.add(BookDetailsPreviewRequested(book)),
      expect: () => [libraryState(saved)],
      verify: (_) => verifyNever(() => search.getBookDetails(any())),
    );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'add switches the page to library mode',
      setUp: () {
        when(() => library.findCachedByExternalId(any())).thenReturn(null);
        when(() => addBook(any(), any())).thenAnswer((_) async => saved);
      },
      build: build,
      seed: () => BookDetailsState(
        status: RequestStatus.success,
        book: buildBook(description: 'd'),
      ),
      act: (bloc) =>
          bloc.add(const BookDetailsAddRequested(ReadingStatus.reading)),
      expect: () => [
        BookDetailsState(
          status: RequestStatus.success,
          book: buildBook(description: 'd'),
          saveStatus: RequestStatus.loading,
        ),
        BookDetailsState(
          status: RequestStatus.success,
          book: saved.book,
          userBook: saved,
          saveStatus: RequestStatus.success,
        ),
      ],
    );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'add failure keeps the preview and reports the failure',
      setUp: () => when(() => addBook(any(), any()))
          .thenThrow(const Failure(FailureCode.server)),
      build: build,
      seed: () => BookDetailsState(status: RequestStatus.success, book: book),
      act: (bloc) =>
          bloc.add(const BookDetailsAddRequested(ReadingStatus.read)),
      expect: () => [
        BookDetailsState(
          status: RequestStatus.success,
          book: book,
          saveStatus: RequestStatus.loading,
        ),
        BookDetailsState(
          status: RequestStatus.success,
          book: book,
          saveStatus: RequestStatus.failure,
          failure: const Failure(FailureCode.server),
        ),
      ],
    );
  });

  group('editing a saved book', () {
    blocTest<BookDetailsBloc, BookDetailsState>(
      'rating: optimistic update, then persisted value',
      setUp: () => when(() => library.update(any()))
          .thenAnswer((i) async => i.positionalArguments.first as UserBook),
      build: build,
      seed: () => libraryState(saved),
      act: (bloc) => bloc.add(const BookDetailsRatingChanged(4)),
      expect: () => [
        isA<BookDetailsState>()
            .having((s) => s.userBook?.rating, 'rating', 4)
            .having((s) => s.saveStatus, 'saveStatus', RequestStatus.loading),
        isA<BookDetailsState>()
            .having((s) => s.userBook?.rating, 'rating', 4)
            .having((s) => s.saveStatus, 'saveStatus', RequestStatus.success),
      ],
    );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'clearing the rating sends null',
      setUp: () => when(() => library.update(any()))
          .thenAnswer((i) async => i.positionalArguments.first as UserBook),
      build: build,
      seed: () => libraryState(buildUserBook(book: book, rating: 3)),
      act: (bloc) => bloc.add(const BookDetailsRatingChanged(null)),
      verify: (_) {
        final updated = verify(() => library.update(captureAny()))
            .captured
            .single as UserBook;
        expect(updated.rating, isNull);
      },
    );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'status change to reading sets startedAt',
      setUp: () => when(() => library.update(any()))
          .thenAnswer((i) async => i.positionalArguments.first as UserBook),
      build: build,
      seed: () => libraryState(saved),
      act: (bloc) =>
          bloc.add(const BookDetailsStatusChanged(ReadingStatus.reading)),
      verify: (_) {
        final updated = verify(() => library.update(captureAny()))
            .captured
            .single as UserBook;
        expect(updated.status, ReadingStatus.reading);
        expect(updated.startedAt, isNotNull);
      },
    );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'progress reaching the last page marks the book as read',
      setUp: () => when(() => library.update(any()))
          .thenAnswer((i) async => i.positionalArguments.first as UserBook),
      build: build,
      seed: () => libraryState(
        buildUserBook(
          book: book,
          status: ReadingStatus.reading,
          currentPage: 100,
        ),
      ),
      act: (bloc) => bloc.add(const BookDetailsProgressChanged(400)),
      verify: (_) {
        final updated = verify(() => library.update(captureAny()))
            .captured
            .single as UserBook;
        expect(updated.status, ReadingStatus.read);
        expect(updated.finishedAt, isNotNull);
      },
    );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'rolls back to the previous value when saving fails',
      setUp: () => when(() => library.update(any()))
          .thenThrow(const Failure(FailureCode.network)),
      build: build,
      seed: () => libraryState(saved),
      act: (bloc) => bloc.add(const BookDetailsRatingChanged(5)),
      expect: () => [
        isA<BookDetailsState>().having((s) => s.userBook?.rating, 'rating', 5),
        libraryState(saved).copyWith(
          saveStatus: RequestStatus.failure,
          failure: () => const Failure(FailureCode.network),
        ),
      ],
    );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'blank notes are stored as null',
      setUp: () => when(() => library.update(any()))
          .thenAnswer((i) async => i.positionalArguments.first as UserBook),
      build: build,
      seed: () => libraryState(
        UserBook(
          id: 'ub-1',
          book: book,
          status: ReadingStatus.reading,
          notes: 'old',
          createdAt: DateTime(2024),
        ),
      ),
      act: (bloc) => bloc.add(const BookDetailsNotesChanged('   ')),
      verify: (_) {
        final updated = verify(() => library.update(captureAny()))
            .captured
            .single as UserBook;
        expect(updated.notes, isNull);
      },
    );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'does not hit the repository when nothing changed',
      build: build,
      seed: () => libraryState(saved),
      act: (bloc) =>
          bloc.add(const BookDetailsStatusChanged(ReadingStatus.wantToRead)),
      expect: () => const <BookDetailsState>[],
      verify: (_) => verifyNever(() => library.update(any())),
    );
  });

  group('removal', () {
    blocTest<BookDetailsBloc, BookDetailsState>(
      'removes the book and flags removed',
      setUp: () => when(() => library.remove('ub-1')).thenAnswer((_) async {}),
      build: build,
      seed: () => libraryState(saved),
      act: (bloc) => bloc.add(const BookDetailsRemoveRequested()),
      expect: () => [
        libraryState(saved).copyWith(saveStatus: RequestStatus.loading),
        libraryState(saved)
            .copyWith(saveStatus: RequestStatus.success, removed: true),
      ],
    );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'reports failure and stays on the page',
      setUp: () => when(() => library.remove(any()))
          .thenThrow(const Failure(FailureCode.server)),
      build: build,
      seed: () => libraryState(saved),
      act: (bloc) => bloc.add(const BookDetailsRemoveRequested()),
      expect: () => [
        libraryState(saved).copyWith(saveStatus: RequestStatus.loading),
        libraryState(saved).copyWith(
          saveStatus: RequestStatus.failure,
          failure: () => const Failure(FailureCode.server),
        ),
      ],
    );
  });
}
