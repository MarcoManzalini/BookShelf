import 'package:flutter/material.dart';

import '../../../../core/utils/minutes_text.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/book_format.dart';
import '../../domain/entities/book_vibe.dart';
import '../../domain/entities/user_book.dart';

extension BookFormatUi on BookFormat {
  String label(AppLocalizations l10n) => switch (this) {
        BookFormat.paper => l10n.formatPaper,
        BookFormat.ebook => l10n.formatEbook,
        BookFormat.audio => l10n.formatAudio,
      };

  IconData get icon => switch (this) {
        BookFormat.paper => Icons.menu_book_rounded,
        BookFormat.ebook => Icons.tablet_android_rounded,
        BookFormat.audio => Icons.headphones_rounded,
      };
}

extension BookMoodUi on BookMood {
  String label(AppLocalizations l10n) => switch (this) {
        BookMood.adventurous => l10n.moodAdventurous,
        BookMood.challenging => l10n.moodChallenging,
        BookMood.dark => l10n.moodDark,
        BookMood.emotional => l10n.moodEmotional,
        BookMood.funny => l10n.moodFunny,
        BookMood.hopeful => l10n.moodHopeful,
        BookMood.informative => l10n.moodInformative,
        BookMood.inspiring => l10n.moodInspiring,
        BookMood.lighthearted => l10n.moodLighthearted,
        BookMood.mysterious => l10n.moodMysterious,
        BookMood.reflective => l10n.moodReflective,
        BookMood.relaxing => l10n.moodRelaxing,
        BookMood.sad => l10n.moodSad,
        BookMood.tense => l10n.moodTense,
      };
}

extension ReadingPaceUi on ReadingPace {
  String label(AppLocalizations l10n) => switch (this) {
        ReadingPace.slow => l10n.paceSlow,
        ReadingPace.medium => l10n.paceMedium,
        ReadingPace.fast => l10n.paceFast,
      };
}

extension UserBookProgressText on UserBook {
  /// "120 / 400 pagine", or "2 h 10 min di 11 h 30 min" for an audiobook.
  String progressLabel(AppLocalizations l10n) {
    final total = progressTotal;
    final page = total != null && currentPage > total ? total : currentPage;
    if (isAudio) {
      final current = MinutesText.format(l10n, page);
      return total == null
          ? current
          : l10n.positionOfTotal(current, MinutesText.format(l10n, total));
    }
    return total != null
        ? l10n.pagesProgress(page, total)
        : l10n.currentPageOnly(page);
  }
}
