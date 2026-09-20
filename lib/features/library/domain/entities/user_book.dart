import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../search/domain/entities/book.dart';
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

  int? get pageCount => book.pageCount;

  /// 0..1, or null when it cannot be computed.
  double? get progress {
    if (status == ReadingStatus.read) return 1;
    final total = pageCount;
    if (total == null || total <= 0) return null;
    return (currentPage / total).clamp(0.0, 1.0);
  }

  /// [ValueGetter] parameters allow explicitly setting a field to null.
  UserBook copyWith({
    ReadingStatus? status,
    int? currentPage,
    ValueGetter<int?>? rating,
    ValueGetter<String?>? notes,
    ValueGetter<DateTime?>? startedAt,
    ValueGetter<DateTime?>? finishedAt,
  }) {
    return UserBook(
      id: id,
      book: book,
      status: status ?? this.status,
      createdAt: createdAt,
      currentPage: currentPage ?? this.currentPage,
      rating: rating != null ? rating() : this.rating,
      notes: notes != null ? notes() : this.notes,
      startedAt: startedAt != null ? startedAt() : this.startedAt,
      finishedAt: finishedAt != null ? finishedAt() : this.finishedAt,
    );
  }

  UserBook withStatus(ReadingStatus newStatus, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    switch (newStatus) {
      case ReadingStatus.wantToRead:
        return copyWith(status: newStatus, finishedAt: () => null);
      case ReadingStatus.reading:
        return copyWith(
          status: newStatus,
          startedAt: () => startedAt ?? today,
          finishedAt: () => null,
        );
      case ReadingStatus.read:
        return copyWith(
          status: newStatus,
          currentPage: pageCount ?? currentPage,
          startedAt: () => startedAt ?? today,
          finishedAt: () => finishedAt ?? today,
        );
    }
  }

  UserBook withProgress(int page, {DateTime? now}) {
    final max = pageCount;
    final clamped = max != null ? page.clamp(0, max) : (page < 0 ? 0 : page);
    final updated = copyWith(currentPage: clamped);
    if (max != null && clamped >= max) {
      return updated.withStatus(ReadingStatus.read, now: now);
    }
    if (clamped > 0 && status == ReadingStatus.wantToRead) {
      return updated.withStatus(ReadingStatus.reading, now: now);
    }
    return updated;
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
      ];
}
