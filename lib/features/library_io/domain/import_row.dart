import 'package:equatable/equatable.dart';

import '../../library/domain/entities/reading_status.dart';

/// One book from a Goodreads (or BookShelf) CSV file or an Open Library
/// reading log, before it is matched to a real book.
class ImportRow extends Equatable {
  const ImportRow({
    required this.title,
    required this.status,
    this.author,
    this.isbn13,
    this.isbn10,
    this.workId,
    this.rating,
    this.pages,
    this.finishedOn,
    this.addedOn,
    this.notes,
    this.shelves = const [],
    this.earlierReads = 0,
  });

  final String title;
  final String? author;
  final String? isbn13;
  final String? isbn10;

  /// Open Library work id (`OL45804W`), when the source already knows it.
  final String? workId;
  final ReadingStatus status;

  /// 1-5; Goodreads uses 0 for "not rated", which becomes null.
  final int? rating;
  final int? pages;
  final DateTime? finishedOn;
  final DateTime? addedOn;

  /// The reader's review and private notes, merged.
  final String? notes;

  /// Custom shelves, without Goodreads' three built-in ones.
  final List<String> shelves;

  /// Finished reads before the one [status] describes ("Read Count" minus
  /// the current read). Goodreads does not say when they happened.
  final int earlierReads;

  /// "Dune by Frank Herbert", for messages.
  String get label => author == null ? title : '$title — $author';

  @override
  List<Object?> get props => [
        title,
        author,
        isbn13,
        isbn10,
        workId,
        status,
        rating,
        pages,
        finishedOn,
        addedOn,
        notes,
        shelves,
        earlierReads,
      ];
}
