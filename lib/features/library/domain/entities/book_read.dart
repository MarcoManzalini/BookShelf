import 'package:equatable/equatable.dart';

/// One earlier, finished read of a book the reader has read more than once.
/// The read in progress (or the only one) stays on the book itself.
class BookRead extends Equatable {
  const BookRead({this.startedAt, this.finishedAt});

  /// Either date may be unknown, e.g. for reads imported from Goodreads,
  /// which only records how many times a book was read.
  final DateTime? startedAt;
  final DateTime? finishedAt;

  factory BookRead.fromJson(Map<String, dynamic> json) => BookRead(
        startedAt: _parse(json['started_at']),
        finishedAt: _parse(json['finished_at']),
      );

  Map<String, dynamic> toJson() => {
        'started_at': _format(startedAt),
        'finished_at': _format(finishedAt),
      };

  static DateTime? _parse(Object? raw) {
    if (raw is! String) return null;
    final date = DateTime.tryParse(raw);
    return date == null ? null : DateTime(date.year, date.month, date.day);
  }

  static String? _format(DateTime? date) {
    if (date == null) return null;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  @override
  List<Object?> get props => [startedAt, finishedAt];
}
