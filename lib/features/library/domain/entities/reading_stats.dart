import 'package:equatable/equatable.dart';

import 'reading_status.dart';
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
      if (b.status != ReadingStatus.read) continue;
      read++;
      pages += b.pageCount ?? 0;
      if (b.finishedAt?.year == year) thisYear++;
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
