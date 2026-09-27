import 'dart:ui';

import '../../../l10n/gen/app_localizations.dart';

/// Strings for notifications, which are written without a widget tree: the
/// device language if the app supports it, Italian otherwise (as the app).
AppLocalizations deviceL10n(Locale locale) => lookupAppLocalizations(
      locale.languageCode == 'en' ? const Locale('en') : const Locale('it'),
    );
