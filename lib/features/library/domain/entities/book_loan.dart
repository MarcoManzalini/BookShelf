import 'package:equatable/equatable.dart';

enum LoanKind {
  /// The reader lent their copy to someone.
  lent('lent'),

  /// The reader borrowed it, from a person or a library.
  borrowed('borrowed');

  const LoanKind(this.dbValue);

  final String dbValue;

  static LoanKind? fromDb(String? value) =>
      LoanKind.values.where((k) => k.dbValue == value).firstOrNull;
}

/// A copy that is out on loan, one way or the other.
class BookLoan extends Equatable {
  const BookLoan({
    required this.kind,
    required this.person,
    required this.since,
    this.due,
  });

  final LoanKind kind;

  /// Who has it, or who lent it (a friend, "Biblioteca Sormani", ...).
  final String person;
  final DateTime since;

  /// When it has to come back, if agreed.
  final DateTime? due;

  static const maxPersonLength = 80;

  /// Past the due date (the due day itself is still fine).
  bool isOverdue(DateTime now) {
    final d = due;
    if (d == null) return false;
    return DateTime(now.year, now.month, now.day).isAfter(d);
  }

  @override
  List<Object?> get props => [kind, person, since, due];
}
