/// Major literary genres offered on the Explore page.
enum ExploreGenre {
  fantasy('fantasy'),
  scienceFiction('science fiction'),
  mystery('mystery'),
  thriller('thriller'),
  romance('romance'),
  historicalFiction('historical fiction'),
  horror('horror'),
  classics('classics'),
  biography('biography'),
  youngAdult('young adult');

  const ExploreGenre(this.subject);

  /// Open Library subject the genre is searched by.
  final String subject;
}
