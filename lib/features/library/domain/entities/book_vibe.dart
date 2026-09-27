/// How a book feels, StoryGraph style: a few moods and the pace.
enum BookMood {
  adventurous('adventurous'),
  challenging('challenging'),
  dark('dark'),
  emotional('emotional'),
  funny('funny'),
  hopeful('hopeful'),
  informative('informative'),
  inspiring('inspiring'),
  lighthearted('lighthearted'),
  mysterious('mysterious'),
  reflective('reflective'),
  relaxing('relaxing'),
  sad('sad'),
  tense('tense');

  const BookMood(this.dbValue);

  final String dbValue;

  /// More than this and the moods stop describing the book.
  static const maxPerBook = 3;

  /// Unknown values (from a newer app version) are dropped.
  static List<BookMood> fromDb(Iterable<String> values) => [
        for (final value in values)
          ...BookMood.values.where((m) => m.dbValue == value),
      ];
}

enum ReadingPace {
  slow('slow'),
  medium('medium'),
  fast('fast');

  const ReadingPace(this.dbValue);

  final String dbValue;

  static ReadingPace? fromDb(String? value) =>
      ReadingPace.values.where((p) => p.dbValue == value).firstOrNull;
}
