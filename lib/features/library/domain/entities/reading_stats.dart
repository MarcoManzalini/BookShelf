import 'package:equatable/equatable.dart';

import 'user_book.dart';

class ReadingStats extends Equatable {
  const ReadingStats({
    required this.booksRead,
    required this.totalPages,
    required this.booksThisYear,
  });

  factory ReadingStats.fromBooks(List<UserBook> books, {DateTime? now}) {
    final year = (now ?? DateTime.now()).year;
    var read = 0;
    var pages = 0;
    var thisYear = 0;
    for (final b in books) {
      // A book read twice counts once as a book, but its pages and each
      // finish (towards the yearly count) count every time.
      final reads = b.completedReads;
      if (reads.isEmpty) continue;
      read++;
      // Audiobooks are listened to: their time is in the reading log.
      if (!b.isAudio) pages += (b.pageCount ?? 0) * reads.length;
      thisYear += reads.where((r) => r.finishedAt?.year == year).length;
    }
    return ReadingStats(
      booksRead: read,
      totalPages: pages,
      booksThisYear: thisYear,
    );
  }

  final int booksRead;
  final int totalPages;
  final int booksThisYear;

  @override
  List<Object?> get props => [booksRead, totalPages, booksThisYear];
}
