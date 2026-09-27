import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../search/domain/entities/book.dart';
import '../../../search/domain/entities/book_edition.dart';
import 'book_format.dart';
import 'book_loan.dart';
import 'book_read.dart';
import 'book_series.dart';
import 'book_vibe.dart';
import 'reading_status.dart';

class UserBook extends Equatable {
  const UserBook({
    required this.id,
    required this.book,
    required this.status,
    required this.createdAt,
    this.currentPage = 0,
    this.rating,
    this.notes,
    this.startedAt,
    this.finishedAt,
    this.shelves = const [],
    this.pastReads = const [],
    this.format = BookFormat.paper,
    this.durationMinutes,
    this.series,
    this.moods = const [],
    this.pace,
    this.loan,
  });

  final String id;
  final Book book;
  final ReadingStatus status;
  final int currentPage;
  final int? rating;
  final String? notes;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final DateTime createdAt;

  /// Custom shelves this book is on (see `ShelfNames`).
  final List<String> shelves;

  /// Earlier finished reads, for books read more than once. The current read
  /// is [startedAt]..[finishedAt].
  final List<BookRead> pastReads;

  final BookFormat format;

  /// Length of an audiobook. For audiobooks [currentPage] is the minute
  /// reached rather than a page.
  final int? durationMinutes;

  final BookSeries? series;
  final List<BookMood> moods;
  final ReadingPace? pace;

  /// Set while the copy is lent out or borrowed.
  final BookLoan? loan;

  bool get isAudio => format == BookFormat.audio;

  /// Pages, or minutes for an audiobook; null when unknown.
  int? get progressTotal => isAudio ? durationMinutes : pageCount;

  /// Every finished read, the earlier ones and the current one if done.
  List<BookRead> get completedReads => [
        ...pastReads,
        if (status == ReadingStatus.read)
          BookRead(startedAt: startedAt, finishedAt: finishedAt),
      ];

  /// How many times the book was read to the end.
  int get readCount => completedReads.length;

  int? get pageCount => book.pageCount;

  /// 0..1, or null when it cannot be computed.
  double? get progress {
    if (status == ReadingStatus.read) return 1;
    final total = progressTotal;
    if (total == null || total <= 0) return null;
    return (currentPage / total).clamp(0.0, 1.0);
  }

  /// [ValueGetter] parameters allow explicitly setting a field to null.
  UserBook copyWith({
    Book? book,
    List<String>? shelves,
    List<BookRead>? pastReads,
    BookFormat? format,
    ValueGetter<int?>? durationMinutes,
    ValueGetter<BookSeries?>? series,
    List<BookMood>? moods,
    ValueGetter<ReadingPace?>? pace,
    ValueGetter<BookLoan?>? loan,
    ReadingStatus? status,
    int? currentPage,
    ValueGetter<int?>? rating,
    ValueGetter<String?>? notes,
    ValueGetter<DateTime?>? startedAt,
    ValueGetter<DateTime?>? finishedAt,
  }) {
    return UserBook(
      id: id,
      book: book ?? this.book,
      shelves: shelves ?? this.shelves,
      pastReads: pastReads ?? this.pastReads,
      format: format ?? this.format,
      durationMinutes:
          durationMinutes != null ? durationMinutes() : this.durationMinutes,
      series: series != null ? series() : this.series,
      moods: moods ?? this.moods,
      pace: pace != null ? pace() : this.pace,
      loan: loan != null ? loan() : this.loan,
      status: status ?? this.status,
      createdAt: createdAt,
      currentPage: currentPage ?? this.currentPage,
      rating: rating != null ? rating() : this.rating,
      notes: notes != null ? notes() : this.notes,
      startedAt: startedAt != null ? startedAt() : this.startedAt,
      finishedAt: finishedAt != null ? finishedAt() : this.finishedAt,
    );
  }

  /// The same reading record, with the book's details taken from [edition].
  /// The bookmark follows the new page count: a finished book stays on its
  /// last page, one in progress never ends up past the end.
  UserBook withEdition(BookEdition edition) {
    final changed = copyWith(book: edition.applyTo(book));
    final total = changed.progressTotal;
    if (total == null || isAudio) return changed;
    final finished = status == ReadingStatus.read;
    return finished || currentPage > total
        ? changed.copyWith(currentPage: total)
        : changed;
  }

  UserBook withStatus(ReadingStatus newStatus, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    switch (newStatus) {
      case ReadingStatus.wantToRead:
        return copyWith(status: newStatus, finishedAt: () => null);
      case ReadingStatus.reading:
      case ReadingStatus.paused:
      case ReadingStatus.abandoned:
        return copyWith(
          status: newStatus,
          startedAt: () => startedAt ?? today,
          finishedAt: () => null,
        );
      case ReadingStatus.read:
        return copyWith(
          status: newStatus,
          currentPage: progressTotal ?? currentPage,
          startedAt: () => startedAt ?? today,
          finishedAt: () => finishedAt ?? today,
        );
    }
  }

  UserBook withProgress(int page, {DateTime? now}) {
    final max = progressTotal;
    final clamped = max != null ? page.clamp(0, max) : (page < 0 ? 0 : page);
    final updated = copyWith(currentPage: clamped);
    if (max != null && clamped >= max) {
      return updated.withStatus(ReadingStatus.read, now: now);
    }
    // Moving the bookmark means the reader is (back to) reading it.
    final resumed = status.isOnHold && clamped > currentPage;
    if ((clamped > 0 && status == ReadingStatus.wantToRead) || resumed) {
      return updated.withStatus(ReadingStatus.reading, now: now);
    }
    return updated;
  }

  /// Starts reading the book again: the finished read moves to [pastReads]
  /// and a new one begins today from the first page.
  UserBook withReread({DateTime? now}) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    return copyWith(
      pastReads: [
        ...pastReads,
        if (status == ReadingStatus.read)
          BookRead(startedAt: startedAt, finishedAt: finishedAt ?? today),
      ],
      status: ReadingStatus.reading,
      currentPage: 0,
      startedAt: () => today,
      finishedAt: () => null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        book,
        status,
        currentPage,
        rating,
        notes,
        startedAt,
        finishedAt,
        createdAt,
        shelves,
        pastReads,
        format,
        durationMinutes,
        series,
        moods,
        pace,
        loan,
      ];
}
