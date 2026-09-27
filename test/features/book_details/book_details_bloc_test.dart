import 'package:bloc_test/bloc_test.dart';
import 'package:bookshelf/core/errors/failure.dart';
import 'package:bookshelf/core/utils/request_status.dart';
import 'package:bookshelf/features/book_details/presentation/bloc/book_details_bloc.dart';
import 'package:bookshelf/features/library/domain/entities/book_format.dart';
import 'package:bookshelf/features/library/domain/entities/book_loan.dart';
import 'package:bookshelf/features/library/domain/entities/book_read.dart';
import 'package:bookshelf/features/library/domain/entities/book_vibe.dart';
import 'package:bookshelf/features/library/domain/entities/reading_status.dart';
import 'package:bookshelf/features/library/domain/entities/user_book.dart';
import 'package:bookshelf/features/quotes/domain/entities/book_quote.dart';
import 'package:bookshelf/features/search/domain/entities/author_info.dart';
import 'package:bookshelf/features/search/domain/entities/book.dart';
import 'package:bookshelf/features/stats/domain/entities/reading_log.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockLibraryRepository library;
  late MockBookSearchRepository search;
  late MockAddBookToLibrary addBook;
  late MockReadingLogRepository logs;
  late MockQuoteRepository quotes;

  final book = buildBook();
  final saved = buildUserBook(book: book);

  setUpAll(() {
    registerFallbackValue(buildUserBook());
    registerFallbackValue(buildBook());
    registerFallbackValue(ReadingStatus.read);
    registerFallbackValue(
      BookQuote(
        id: 'q',
        userBookId: 'ub',
        text: 't',
        createdAt: DateTime(2026),
      ),
    );
  });

  setUp(() {
    library = MockLibraryRepository();
    search = MockBookSearchRepository();
    addBook = MockAddBookToLibrary();
    logs = MockReadingLogRepository();
    when(() => logs.forBook(any())).thenAnswer((_) async => []);
    quotes = MockQuoteRepository();
    when(() => quotes.forBook(any())).thenAnswer((_) async => []);
    when(
      () => logs.add(
        userBookId: any(named: 'userBookId'),
        pages: any(named: 'pages'),
        minutes: any(named: 'minutes'),
        endPage: any(named: 'endPage'),
        on: any(named: 'on'),
      ),
    ).thenAnswer(
      (i) async => ReadingLog(
        id: 'log-${i.namedArguments[#pages]}',
        userBookId: i.namedArguments[#userBookId] as String,
        loggedOn: DateTime(2026, 9, 20),
        pages: i.namedArguments[#pages] as int,
        minutes: i.namedArguments[#minutes] as int?,
        endPage: i.namedArguments[#endPage] as int?,
      ),
    );
    // Saved books are looked up on Open Library for author ids and rating.
    when(() => search.getBookDetails(any()))
        .thenAnswer((i) async => i.positionalArguments.first as Book);
  });

  BookDetailsBloc build() => BookDetailsBloc(
        libraryRepository: library,
        searchRepository: search,
        addBook: addBook,
        readingLogs: logs,
        quotes: quotes,
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

  group('extras', () {
    const author = AuthorInfo(key: 'OL9A', name: 'Frank Herbert');
    final withAuthor = book.copyWith(
      authorKeys: const ['OL9A'],
      subjects: const ['Science fiction', 'Ecology'],
    );
    final other = buildBook(id: 'OL2W', title: 'Dune Messiah');
    final similar = buildBook(id: 'OL3W', title: 'Earth Abides');

    blocTest<BookDetailsBloc, BookDetailsState>(
      'loads author, more by author and similar books for a saved book',
      setUp: () {
        when(() => library.getById('ub-1')).thenAnswer(
          (_) async => buildUserBook(book: withAuthor),
        );
        when(() => search.getAuthor('OL9A')).thenAnswer((_) async => author);
        when(() => search.getBooksByAuthor('OL9A', exclude: 'OL1W'))
            .thenAnswer((_) async => [other]);
        when(() => search.getSimilarBooks(withAuthor))
            .thenAnswer((_) async => [similar]);
      },
      build: build,
      act: (bloc) => bloc.add(const BookDetailsLibraryRequested('ub-1')),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.author, author);
        expect(bloc.state.moreByAuthor, [other]);
        expect(bloc.state.similarBooks, [similar]);
      },
    );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'a failing section stays empty without failing the page',
      setUp: () {
        when(() => library.getById('ub-1')).thenAnswer(
          (_) async => buildUserBook(book: withAuthor),
        );
        when(() => search.getAuthor(any()))
            .thenThrow(const Failure(FailureCode.network));
        when(
          () => search.getBooksByAuthor(any(), exclude: any(named: 'exclude')),
        ).thenAnswer((_) async => [other]);
        when(() => search.getSimilarBooks(any()))
            .thenThrow(const Failure(FailureCode.timeout));
      },
      build: build,
      act: (bloc) => bloc.add(const BookDetailsLibraryRequested('ub-1')),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.status, RequestStatus.success);
        expect(bloc.state.author, isNull);
        expect(bloc.state.moreByAuthor, [other]);
        expect(bloc.state.similarBooks, isEmpty);
      },
    );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'uses the author ids found by the work lookup for saved books',
      setUp: () {
        when(() => library.getById('ub-1')).thenAnswer((_) async => saved);
        when(() => search.getBookDetails(saved.book)).thenAnswer(
          (_) async => saved.book.copyWith(authorKeys: const ['OL9A']),
        );
        when(() => search.getAuthor('OL9A')).thenAnswer((_) async => author);
        when(() => search.getBooksByAuthor('OL9A', exclude: 'OL1W'))
            .thenAnswer((_) async => const []);
      },
      build: build,
      act: (bloc) => bloc.add(const BookDetailsLibraryRequested('ub-1')),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.book?.authorKeys, ['OL9A']);
        expect(bloc.state.author, author);
        verifyNever(() => search.getSimilarBooks(any()));
      },
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
      verify: (_) => verify(() => search.getBookDetails(saved.book)).called(1),
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
      'moving the bookmark forward logs the pages read',
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
      act: (bloc) => bloc.add(const BookDetailsProgressChanged(150)),
      verify: (bloc) {
        verify(
          () => logs.add(userBookId: 'ub-1', pages: 50, endPage: 150),
        ).called(1);
        expect(bloc.state.logs.single.pages, 50);
      },
    );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'moving the bookmark backwards logs nothing',
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
      act: (bloc) => bloc.add(const BookDetailsProgressChanged(40)),
      verify: (bloc) {
        verifyNever(
          () => logs.add(
            userBookId: any(named: 'userBookId'),
            pages: any(named: 'pages'),
            minutes: any(named: 'minutes'),
            endPage: any(named: 'endPage'),
            on: any(named: 'on'),
          ),
        );
        expect(bloc.state.logs, isEmpty);
      },
    );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'a session saves the page and logs pages and minutes',
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
      act: (bloc) =>
          bloc.add(const BookDetailsSessionLogged(endPage: 130, minutes: 25)),
      verify: (bloc) {
        expect(bloc.state.userBook!.currentPage, 130);
        verify(
          () => logs.add(
            userBookId: 'ub-1',
            pages: 30,
            minutes: 25,
            endPage: 130,
          ),
        ).called(1);
      },
    );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'a time-only session (same page) is still logged',
      build: build,
      seed: () => libraryState(
        buildUserBook(
          book: book,
          status: ReadingStatus.reading,
          currentPage: 100,
        ),
      ),
      act: (bloc) =>
          bloc.add(const BookDetailsSessionLogged(endPage: 100, minutes: 15)),
      verify: (bloc) {
        verify(
          () => logs.add(
            userBookId: 'ub-1',
            pages: 0,
            minutes: 15,
            endPage: 100,
          ),
        ).called(1);
      },
    );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'a session that saves nothing (no pages, no minutes) logs nothing',
      build: build,
      seed: () => libraryState(
        buildUserBook(
          book: book,
          status: ReadingStatus.reading,
          currentPage: 100,
        ),
      ),
      act: (bloc) => bloc.add(const BookDetailsSessionLogged(endPage: 100)),
      verify: (_) => verifyNever(
        () => logs.add(
          userBookId: any(named: 'userBookId'),
          pages: any(named: 'pages'),
          minutes: any(named: 'minutes'),
          endPage: any(named: 'endPage'),
          on: any(named: 'on'),
        ),
      ),
    );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'a failing log write never fails the reading update',
      setUp: () {
        when(() => library.update(any()))
            .thenAnswer((i) async => i.positionalArguments.first as UserBook);
        when(
          () => logs.add(
            userBookId: any(named: 'userBookId'),
            pages: any(named: 'pages'),
            minutes: any(named: 'minutes'),
            endPage: any(named: 'endPage'),
            on: any(named: 'on'),
          ),
        ).thenThrow(const Failure(FailureCode.network));
      },
      build: build,
      seed: () => libraryState(
        buildUserBook(
          book: book,
          status: ReadingStatus.reading,
          currentPage: 100,
        ),
      ),
      act: (bloc) => bloc.add(const BookDetailsProgressChanged(150)),
      verify: (bloc) {
        expect(bloc.state.userBook!.currentPage, 150);
        expect(bloc.state.saveStatus, RequestStatus.success);
        expect(bloc.state.failure, isNull);
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

  group('re-reads', () {
    final finished = buildUserBook(
      status: ReadingStatus.read,
      currentPage: 400,
      startedAt: DateTime(2025, 1, 1),
      finishedAt: DateTime(2025, 2, 1),
    );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'reading again saves the old read in the history',
      setUp: () => when(() => library.update(any()))
          .thenAnswer((i) async => i.positionalArguments.first as UserBook),
      build: build,
      seed: () => libraryState(finished),
      act: (bloc) => bloc.add(const BookDetailsRereadStarted()),
      verify: (bloc) {
        final book = bloc.state.userBook!;
        expect(book.status, ReadingStatus.reading);
        expect(book.currentPage, 0);
        expect(book.pastReads.single.finishedAt, DateTime(2025, 2, 1));
      },
    );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'adding and removing earlier reads',
      setUp: () => when(() => library.update(any()))
          .thenAnswer((i) async => i.positionalArguments.first as UserBook),
      build: build,
      seed: () => libraryState(finished),
      act: (bloc) async {
        bloc
          ..add(BookDetailsPastReadAdded(BookRead(finishedAt: DateTime(2020))))
          ..add(const BookDetailsPastReadAdded(BookRead()))
          ..add(const BookDetailsPastReadAdded(BookRead()))
          ..add(const BookDetailsPastReadRemoved(BookRead()));
      },
      verify: (bloc) {
        // Only one of the two undated reads goes.
        expect(bloc.state.userBook!.pastReads, [
          BookRead(finishedAt: DateTime(2020)),
          const BookRead(),
        ]);
        expect(bloc.state.userBook!.readCount, 3);
      },
    );
  });

  group('quotes', () {
    BookQuote quote(String id, String text, {int? page}) => BookQuote(
          id: id,
          userBookId: saved.id,
          text: text,
          page: page,
          createdAt: DateTime(2026, 9, 1),
        );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'are loaded with a saved book',
      setUp: () {
        when(() => library.getById('ub-1')).thenAnswer((_) async => saved);
        when(() => quotes.forBook('ub-1'))
            .thenAnswer((_) async => [quote('q1', 'Uno')]);
      },
      build: build,
      act: (bloc) => bloc.add(const BookDetailsLibraryRequested('ub-1')),
      verify: (bloc) => expect(bloc.state.quotes, [quote('q1', 'Uno')]),
    );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'a new quote is trimmed, saved and shown first',
      setUp: () => when(
        () => quotes.add(
          userBookId: any(named: 'userBookId'),
          text: any(named: 'text'),
          page: any(named: 'page'),
        ),
      ).thenAnswer(
        (i) async => quote(
          'q2',
          i.namedArguments[#text] as String,
          page: i.namedArguments[#page] as int?,
        ),
      ),
      build: build,
      seed: () => libraryState(saved).copyWith(quotes: [quote('q1', 'Uno')]),
      act: (bloc) =>
          bloc.add(const BookDetailsQuoteSaved(text: '  Due  ', page: 0)),
      expect: () => [
        libraryState(saved).copyWith(
          quotes: [quote('q1', 'Uno')],
          saveStatus: RequestStatus.loading,
        ),
        libraryState(saved).copyWith(
          quotes: [quote('q2', 'Due'), quote('q1', 'Uno')],
          saveStatus: RequestStatus.success,
        ),
      ],
      verify: (_) => verify(
        () => quotes.add(userBookId: 'ub-1', text: 'Due', page: null),
      ).called(1),
    );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'editing replaces the quote in place',
      setUp: () => when(() => quotes.update(any())).thenAnswer(
        (i) async => i.positionalArguments.first as BookQuote,
      ),
      build: build,
      seed: () => libraryState(saved)
          .copyWith(quotes: [quote('q1', 'Uno'), quote('q2', 'Due')]),
      act: (bloc) => bloc
          .add(const BookDetailsQuoteSaved(text: 'Uno!', page: 7, id: 'q1')),
      verify: (bloc) => expect(bloc.state.quotes, [
        quote('q1', 'Uno!', page: 7),
        quote('q2', 'Due'),
      ]),
    );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'a failed delete puts the quote back',
      setUp: () => when(() => quotes.remove('q1'))
          .thenThrow(const Failure(FailureCode.network)),
      build: build,
      seed: () => libraryState(saved).copyWith(quotes: [quote('q1', 'Uno')]),
      act: (bloc) => bloc.add(const BookDetailsQuoteRemoved('q1')),
      expect: () => [
        libraryState(saved),
        libraryState(saved).copyWith(
          quotes: [quote('q1', 'Uno')],
          saveStatus: RequestStatus.failure,
          failure: () => const Failure(FailureCode.network),
        ),
      ],
    );
  });

  group('format, mood and loans', () {
    void savesAsIs() => when(() => library.update(any()))
        .thenAnswer((i) async => i.positionalArguments.first as UserBook);

    final reading = buildUserBook(
      status: ReadingStatus.reading,
      currentPage: 120,
    );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'switching to audiobook restarts the bookmark (pages are not minutes)',
      setUp: savesAsIs,
      build: build,
      seed: () => libraryState(reading),
      act: (bloc) => bloc
        ..add(const BookDetailsFormatChanged(BookFormat.audio))
        ..add(const BookDetailsDurationChanged(600)),
      verify: (bloc) {
        final book = bloc.state.userBook!;
        expect(book.format, BookFormat.audio);
        expect(book.currentPage, 0);
        expect(book.durationMinutes, 600);
      },
    );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'ebook and print share the page bookmark',
      setUp: savesAsIs,
      build: build,
      seed: () => libraryState(reading),
      act: (bloc) => bloc.add(const BookDetailsFormatChanged(BookFormat.ebook)),
      verify: (bloc) => expect(bloc.state.userBook!.currentPage, 120),
    );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'listening logs minutes, not pages',
      setUp: savesAsIs,
      build: build,
      seed: () => libraryState(
        reading.copyWith(
          format: BookFormat.audio,
          durationMinutes: () => 600,
          currentPage: 60,
        ),
      ),
      act: (bloc) => bloc.add(const BookDetailsProgressChanged(90)),
      verify: (_) => verify(
        () => logs.add(
          userBookId: 'ub-1',
          pages: 0,
          minutes: 30,
          endPage: 90,
        ),
      ).called(1),
    );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'at most three moods',
      setUp: savesAsIs,
      build: build,
      seed: () => libraryState(reading),
      act: (bloc) => bloc.add(
        const BookDetailsMoodsChanged([
          BookMood.dark,
          BookMood.tense,
          BookMood.sad,
          BookMood.funny,
        ]),
      ),
      verify: (bloc) => expect(
        bloc.state.userBook!.moods,
        [BookMood.dark, BookMood.tense, BookMood.sad],
      ),
    );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'a loan is set and then returned',
      setUp: savesAsIs,
      build: build,
      seed: () => libraryState(reading),
      act: (bloc) async {
        bloc.add(
          BookDetailsLoanChanged(
            BookLoan(
              kind: LoanKind.lent,
              person: 'Anna',
              since: DateTime(2026, 9, 1),
            ),
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.userBook!.loan?.person, 'Anna');
        bloc.add(const BookDetailsLoanChanged(null));
      },
      verify: (bloc) => expect(bloc.state.userBook!.loan, isNull),
    );
  });
}
