enum CoverSize {
  small('S'),
  medium('M'),
  large('L');

  const CoverSize(this.code);
  final String code;
}

final _openLibrarySize = RegExp(r'-(S|M|L)\.jpg');

/// Open Library cover URLs encode the size as a `-S|M|L.jpg` suffix. We store
/// the large URL and request smaller variants for list thumbnails.
String resizeCoverUrl(String url, CoverSize size) {
  if (!url.contains('covers.openlibrary.org')) return url;
  return url.replaceFirst(_openLibrarySize, '-${size.code}.jpg');
}
