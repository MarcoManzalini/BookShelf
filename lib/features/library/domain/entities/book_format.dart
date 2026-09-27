/// How the book is read. Audiobooks measure progress in minutes, the other
/// formats in pages.
enum BookFormat {
  paper('paper'),
  ebook('ebook'),
  audio('audio');

  const BookFormat(this.dbValue);

  final String dbValue;

  static BookFormat fromDb(String? value) => BookFormat.values.firstWhere(
        (f) => f.dbValue == value,
        orElse: () => BookFormat.paper,
      );
}
