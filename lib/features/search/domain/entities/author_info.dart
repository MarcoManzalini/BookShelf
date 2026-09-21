import 'package:equatable/equatable.dart';

class AuthorInfo extends Equatable {
  const AuthorInfo({
    required this.key,
    required this.name,
    this.bio,
    this.birthDate,
    this.deathDate,
    this.photoUrl,
    this.workCount,
    this.wikipediaUrl,
  });

  /// Open Library author id, e.g. `OL79034A`.
  final String key;
  final String name;
  final String? bio;

  /// Free-form dates as entered on Open Library ("8 October 1920", "1920").
  final String? birthDate;
  final String? deathDate;
  final String? photoUrl;
  final int? workCount;
  final String? wikipediaUrl;

  /// "1920 – 1986", "b. 1920" or null when no date is known.
  String? get lifespan {
    final born = _year(birthDate) ?? birthDate;
    final died = _year(deathDate) ?? deathDate;
    if (born == null && died == null) return null;
    if (born != null && died != null) return '$born – $died';
    if (born != null) return '* $born';
    return '† $died';
  }

  static final _yearPattern = RegExp(r'\b(\d{3,4})\b');

  static String? _year(String? date) =>
      date == null ? null : _yearPattern.firstMatch(date)?.group(1);

  @override
  List<Object?> get props => [
        key,
        name,
        bio,
        birthDate,
        deathDate,
        photoUrl,
        workCount,
        wikipediaUrl,
      ];
}
