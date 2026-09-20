import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/reading_status.dart';

extension ReadingStatusUi on ReadingStatus {
  String label(AppLocalizations l10n) => switch (this) {
        ReadingStatus.wantToRead => l10n.statusWantToRead,
        ReadingStatus.reading => l10n.statusReading,
        ReadingStatus.read => l10n.statusRead,
      };

  IconData get icon => switch (this) {
        ReadingStatus.wantToRead => Icons.bookmark_border_rounded,
        ReadingStatus.reading => Icons.auto_stories_rounded,
        ReadingStatus.read => Icons.check_circle_outline_rounded,
      };
}
