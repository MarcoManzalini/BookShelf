import '../../../../library/domain/entities/user_book.dart';
import '../../../../stats/domain/entities/reading_log.dart';

/// Everything the share cards tell about one reading session.
class ReadingShareData {
  const ReadingShareData({
    required this.title,
    required this.day,
    this.author,
    this.coverUrl,
    this.pages = 0,
    this.minutes,
    this.endPage,
    this.totalPages,
    this.streak,
    this.weekPages,
  });

  factory ReadingShareData.from(UserBook userBook, ReadingLog log) {
    return ReadingShareData(
      title: userBook.book.title,
      author: userBook.book.authors.firstOrNull,
      coverUrl: userBook.book.coverUrl,
      day: log.loggedOn,
      pages: log.pages,
      minutes: log.minutes,
      // An audiobook's bookmark is a minute, not a page the cards can show.
      endPage: userBook.isAudio ? null : log.endPage,
      totalPages: userBook.isAudio ? null : userBook.pageCount,
    );
  }

  final String title;
  final String? author;
  final String? coverUrl;
  final DateTime day;
  final int pages;
  final int? minutes;
  final int? endPage;
  final int? totalPages;

  /// Days in a row the reader read, up to this session. Null while unknown.
  final int? streak;

  /// Pages logged each of the 7 days up to and including [day], oldest
  /// first. Null while unknown.
  final List<int>? weekPages;

  ReadingShareData withStreak(int? streak) => ReadingShareData(
        title: title,
        author: author,
        coverUrl: coverUrl,
        day: day,
        pages: pages,
        minutes: minutes,
        endPage: endPage,
        totalPages: totalPages,
        streak: streak,
        weekPages: weekPages,
      );

  ReadingShareData withWeek(List<int> weekPages) => ReadingShareData(
        title: title,
        author: author,
        coverUrl: coverUrl,
        day: day,
        pages: pages,
        minutes: minutes,
        endPage: endPage,
        totalPages: totalPages,
        streak: streak,
        weekPages: weekPages,
      );

  /// Pages per hour, when both pages and time are known.
  int? get pace {
    final m = minutes;
    if (pages <= 0 || m == null || m <= 0) return null;
    return (pages * 60 / m).round();
  }

  /// Page the session started from, when it can be worked out.
  int? get startPage {
    final end = endPage;
    if (end == null || pages <= 0) return null;
    return (end - pages).clamp(0, end);
  }

  /// 0..1 of the book read at the end of the session.
  double? get progress {
    final end = endPage;
    final total = totalPages;
    if (end == null || total == null || total <= 0) return null;
    return (end / total).clamp(0.0, 1.0);
  }

  /// 0..1 of the book read before the session started.
  double? get progressBefore {
    final from = startPage;
    final total = totalPages;
    if (from == null || total == null || total <= 0) return null;
    return (from / total).clamp(0.0, 1.0);
  }

  /// The number the card is about: pages, or minutes for a time-only session.
  bool get heroIsMinutes => pages <= 0 && (minutes ?? 0) > 0;
  int get heroValue => heroIsMinutes ? minutes! : pages;

  int? get streakDays => (streak ?? 0) > 0 ? streak : null;

  /// True when the session happened on [now]'s calendar day.
  bool isOn(DateTime now) =>
      day.year == now.year && day.month == now.month && day.day == now.day;
}
