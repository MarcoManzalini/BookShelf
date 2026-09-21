import '../../domain/entities/reading_log.dart';

class ReadingLogMapper {
  const ReadingLogMapper._();

  static ReadingLog fromJson(Map<String, dynamic> json) {
    final day = DateTime.parse(json['logged_on'] as String);
    return ReadingLog(
      id: json['id'] as String,
      userBookId: json['user_book_id'] as String,
      loggedOn: DateTime(day.year, day.month, day.day),
      pages: (json['pages'] as num?)?.toInt() ?? 0,
      minutes: (json['minutes'] as num?)?.toInt(),
      endPage: (json['end_page'] as num?)?.toInt(),
    );
  }

  static Map<String, dynamic> toInsertJson({
    required String userBookId,
    required int pages,
    required DateTime on,
    int? minutes,
    int? endPage,
  }) =>
      {
        'user_book_id': userBookId,
        'logged_on': formatDate(on),
        'pages': pages,
        'minutes': minutes,
        'end_page': endPage,
      };

  static String formatDate(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }
}
