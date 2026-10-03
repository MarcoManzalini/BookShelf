import 'dart:async';

import 'package:equatable/equatable.dart';

import '../../../core/errors/failure.dart';
import '../../../core/utils/isbn.dart';
import '../../library/domain/entities/book_read.dart';
import '../../library/domain/entities/reading_status.dart';
import '../../library/domain/entities/shelf_names.dart';
import '../../library/domain/entities/user_book.dart';
import '../../library/domain/repositories/library_repository.dart';
import '../../search/domain/entities/book.dart';
import '../../search/domain/repositories/book_search_repository.dart';
import 'import_row.dart';

class ImportProgress extends Equatable {
  const ImportProgress({
    required this.total,
    this.processed = 0,
    this.imported = 0,
    this.duplicates = 0,
    this.notFound = const [],
    this.failed = const [],
    this.aborted,
    this.cancelled = false,
  });

  final int total;
  final int processed;
  final int imported;

  /// Already in the library.
  final int duplicates;

  /// No matching book was found on Open Library.
  final List<ImportRow> notFound;

  /// Matched, but saving failed.
  final List<ImportRow> failed;

  /// Set when the connection was lost and the import stopped early.
  final Failure? aborted;
  final bool cancelled;

  double get fraction => total == 0 ? 1 : processed / total;

  ImportProgress copyWith({
    int? processed,
    int? imported,
    int? duplicates,
    List<ImportRow>? notFound,
    List<ImportRow>? failed,
    Failure? aborted,
    bool? cancelled,
  }) =>
      ImportProgress(
        total: total,
        processed: processed ?? this.processed,
        imported: imported ?? this.imported,
        duplicates: duplicates ?? this.duplicates,
        notFound: notFound ?? this.notFound,
        failed: failed ?? this.failed,
        aborted: aborted ?? this.aborted,
        cancelled: cancelled ?? this.cancelled,
      );

  @override
  List<Object?> get props => [
        total,
        processed,
        imported,
        duplicates,
        notFound,
        failed,
        aborted,
        cancelled,
      ];
}

/// Turns imported rows into library books: each row is matched to an Open
/// Library book (by work id, ISBN, then title and author) and added with the status,
/// rating, dates, notes and shelves the file carries.
class LibraryImporter {
  LibraryImporter(
    this._search,
    this._library, {
    this.concurrency = 2,
    this.pause = const Duration(milliseconds: 200),
  });

  final BookSearchRepository _search;
  final LibraryRepository _library;

  /// Rows handled at once. Kept low: Open Library asks clients to go easy.
  final int concurrency;

  /// Breather between rows of one worker, for the same reason.
  final Duration pause;

  /// Emits a progress snapshot after every row, and a last one when done.
  Stream<ImportProgress> run(
    List<ImportRow> rows, {
    bool Function()? isCancelled,
  }) {
    final controller = StreamController<ImportProgress>();
    var progress = ImportProgress(total: rows.length);
    var next = 0;
    var stop = false;

    void publish(ImportProgress p) {
      progress = p;
      if (!controller.isClosed) controller.add(p);
    }

    Future<void> worker() async {
      while (!stop) {
        if (isCancelled?.call() ?? false) {
          stop = true;
          publish(progress.copyWith(cancelled: true));
          return;
        }
        if (next >= rows.length) return;
        final row = rows[next++];
        try {
          switch (await _importRow(row)) {
            case _Outcome.imported:
              publish(
                progress.copyWith(
                  processed: progress.processed + 1,
                  imported: progress.imported + 1,
                ),
              );
            case _Outcome.duplicate:
              publish(
                progress.copyWith(
                  processed: progress.processed + 1,
                  duplicates: progress.duplicates + 1,
                ),
              );
            case _Outcome.notFound:
              publish(
                progress.copyWith(
                  processed: progress.processed + 1,
                  notFound: [...progress.notFound, row],
                ),
              );
          }
        } on Failure catch (failure) {
          if (_isConnectivity(failure)) {
            stop = true;
            publish(progress.copyWith(aborted: failure));
            return;
          }
          publish(
            progress.copyWith(
              processed: progress.processed + 1,
              failed: [...progress.failed, row],
            ),
          );
        }
        if (pause > Duration.zero) await Future<void>.delayed(pause);
      }
    }

    () async {
      await Future.wait([
        for (var i = 0; i < concurrency.clamp(1, 8); i++) worker(),
      ]);
      await controller.close();
    }();
    return controller.stream;
  }

  Future<_Outcome> _importRow(ImportRow row) async {
    final book = await _match(row);
    if (book == null) return _Outcome.notFound;
    if (_library.findCachedByExternalId(book.externalId) != null) {
      return _Outcome.duplicate;
    }
    final saved = await _library.add(book, row.status);
    final updated = _apply(saved, row);
    if (updated != saved) {
      try {
        await _library.update(updated);
      } on Failure catch (failure) {
        // The book is in; only the extras (rating, dates...) are missing.
        if (_isConnectivity(failure)) rethrow;
      }
    }
    return _Outcome.imported;
  }

  Future<Book?> _match(ImportRow row) async {
    final workId = row.workId;
    if (workId != null) {
      final book = await _search.findByWorkId(workId);
      if (book != null) return book;
    }
    for (final raw in [row.isbn13, row.isbn10]) {
      final isbn = Isbn.parse(raw);
      if (isbn == null) continue;
      final book = await _search.findByIsbn(isbn);
      if (book != null) return book;
    }
    final query = [row.title, if (row.author != null) row.author!].join(' ');
    final page = await _search.search(query);
    return pickBestMatch(page.books, row);
  }

  /// The first result whose title matches the row's (ignoring subtitles,
  /// series marks and punctuation) and whose author matches when known.
  /// Null when nothing is a confident match: a wrong book is worse than none.
  static Book? pickBestMatch(List<Book> candidates, ImportRow row) {
    final wanted = normalizeTitle(row.title);
    if (wanted.isEmpty) return null;
    final author = row.author == null ? null : _surname(row.author!);
    for (final book in candidates) {
      final title = normalizeTitle(book.title);
      final titleMatches = title == wanted ||
          (title.length >= 4 && wanted.startsWith('$title ')) ||
          (wanted.length >= 4 && title.startsWith('$wanted '));
      if (!titleMatches) continue;
      if (author == null ||
          book.authors.isEmpty ||
          book.authors.any((a) => _normalize(a).contains(author))) {
        return book;
      }
    }
    return null;
  }

  /// "Dune (Dune Chronicles, #1): the first book" -> "dune".
  static String normalizeTitle(String title) {
    final main = title.split(RegExp(r'[(:\[]')).first;
    return _normalize(main);
  }

  static String _surname(String author) {
    final words = _normalize(author).split(' ');
    return words.isEmpty ? '' : words.last;
  }

  static final _nonWord = RegExp(r'[^\p{L}\p{N}\s]', unicode: true);
  static final _spaces = RegExp(r'\s+');

  static String _normalize(String text) => text
      .toLowerCase()
      .replaceAll(_nonWord, ' ')
      .replaceAll(_spaces, ' ')
      .trim();

  UserBook _apply(UserBook saved, ImportRow row) {
    var book = saved;
    if (row.rating != null) book = book.copyWith(rating: () => row.rating);
    if (row.notes != null) book = book.copyWith(notes: () => row.notes);
    if (row.shelves.isNotEmpty) {
      book = book.copyWith(shelves: ShelfNames.clean(row.shelves));
    }
    if (row.pages != null && book.book.pageCount == null) {
      book = book.copyWith(book: book.book.copyWith(pageCount: row.pages));
    }
    if (row.earlierReads > 0) {
      book = book.copyWith(
        pastReads: List.filled(row.earlierReads, const BookRead()),
      );
    }
    switch (row.status) {
      case ReadingStatus.read:
        final finished = row.finishedOn;
        if (finished != null) {
          final added = row.addedOn;
          book = book.copyWith(
            finishedAt: () => finished,
            startedAt: () =>
                (added != null && !added.isAfter(finished)) ? added : finished,
          );
        }
      case ReadingStatus.reading:
      case ReadingStatus.paused:
      case ReadingStatus.abandoned:
        final added = row.addedOn;
        if (added != null) book = book.copyWith(startedAt: () => added);
      case ReadingStatus.wantToRead:
        break;
    }
    return book;
  }

  static bool _isConnectivity(Failure failure) =>
      failure.code == FailureCode.network ||
      failure.code == FailureCode.timeout;
}

enum _Outcome { imported, duplicate, notFound }
