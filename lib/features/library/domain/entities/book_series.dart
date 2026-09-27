import 'package:equatable/equatable.dart';

/// The saga a book belongs to and which of its volumes the book contains.
/// One book can hold several volumes, e.g. an edition of 1Q84 with volumes
/// 1 and 2 in one book and volume 3 in another.
class BookSeries extends Equatable {
  const BookSeries({
    required this.name,
    this.index,
    this.indexEnd,
    this.total,
  });

  final String name;

  /// First volume in the book; fractional for novellas between volumes (2.5).
  final double? index;

  /// Last volume in the book when it holds more than one, else null.
  final double? indexEnd;

  /// How many volumes the saga has, when known.
  final int? total;

  static const maxNameLength = 80;

  /// Last volume the book contains.
  double? get lastIndex => indexEnd ?? index;

  bool get isRange => indexEnd != null && index != null && indexEnd! > index!;

  /// Whether volume [volume] is inside this book.
  bool covers(num volume) {
    final first = index;
    final last = lastIndex;
    return first != null && last != null && volume >= first && volume <= last;
  }

  /// "2", "2.5" or "1–2".
  String? get indexLabel {
    final first = index;
    if (first == null) return null;
    return isRange ? '${_number(first)}–${_number(indexEnd!)}' : _number(first);
  }

  static String _number(double n) =>
      n == n.roundToDouble() ? n.toInt().toString() : n.toString();

  /// The volume that follows this book, if the saga has one. [sagaTotal]
  /// is the saga's length when another book of it knows better.
  int? nextIndex({int? sagaTotal}) {
    final last = lastIndex;
    if (last == null) return null;
    final next = last.floor() + 1;
    final end = sagaTotal ?? total;
    return (end != null && next > end) ? null : next;
  }

  bool sameSagaAs(BookSeries other) => sameName(name, other.name);

  static bool sameName(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

  @override
  List<Object?> get props => [name, index, indexEnd, total];
}
