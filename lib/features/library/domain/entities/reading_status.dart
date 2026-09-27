enum ReadingStatus {
  wantToRead('want_to_read'),
  reading('reading'),
  paused('paused'),
  abandoned('abandoned'),
  read('read');

  const ReadingStatus(this.dbValue);

  final String dbValue;

  /// What a book can be added to the library as: pausing or abandoning only
  /// makes sense for a book already started.
  static const addable = [wantToRead, reading, read];

  /// Started and left open: the reader may still pick it up again.
  bool get isOnHold => this == paused || this == abandoned;

  static ReadingStatus fromDb(String value) => ReadingStatus.values.firstWhere(
        (s) => s.dbValue == value,
        orElse: () => ReadingStatus.wantToRead,
      );
}
