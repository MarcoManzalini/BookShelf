enum ReadingStatus {
  wantToRead('want_to_read'),
  reading('reading'),
  read('read');

  const ReadingStatus(this.dbValue);

  final String dbValue;

  static ReadingStatus fromDb(String value) => ReadingStatus.values.firstWhere(
        (s) => s.dbValue == value,
        orElse: () => ReadingStatus.wantToRead,
      );
}
