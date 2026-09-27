import 'package:flutter/material.dart';

import 'share_cards/photo_share_card.dart';
import 'share_cards/poster_share_card.dart';
import 'share_cards/reading_share_data.dart';
import 'share_cards/stats_share_card.dart';

export 'share_cards/reading_share_data.dart';

/// The looks a session can be shared with.
enum ShareTemplate {
  /// Dark card led by the number and where it took the reader in the book.
  stats,

  /// Poster in the color of the cover, the mascot in the corner.
  poster,

  /// The photo of the reading spot as the backdrop.
  photo,
}

/// The image a reader shares, drawn at a fixed 4:5 size whatever the theme or
/// screen, so the exported picture always looks the same.
class ReadingShareCard extends StatelessWidget {
  const ReadingShareCard({
    super.key,
    required this.data,
    this.template = ShareTemplate.stats,
    this.tint,
    this.photo,
    this.place,
    this.quote,
  });

  final ReadingShareData data;
  final ShareTemplate template;

  /// Dominant color of the cover.
  final Color? tint;

  /// Picture of the place the session happened in.
  final ImageProvider? photo;

  /// Where the session happened; hidden when blank.
  final String? place;

  /// A line from the book, typed in by the reader; hidden when blank.
  final String? quote;

  static const width = 360.0;
  static const height = 640.0;

  @override
  Widget build(BuildContext context) {
    return switch (template) {
      ShareTemplate.stats => StatsShareCard(
          data: data,
          place: place,
          photo: photo,
          quote: quote,
        ),
      ShareTemplate.poster => PosterShareCard(
          data: data,
          tint: tint,
          photo: photo,
          place: place,
          quote: quote,
        ),
      ShareTemplate.photo => PhotoShareCard(
          data: data,
          tint: tint,
          photo: photo,
          place: place,
          quote: quote,
        ),
    };
  }
}
