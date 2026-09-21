const _names = <String, String>{
  'eng': 'English',
  'ita': 'Italiano',
  'fre': 'Français',
  'fra': 'Français',
  'ger': 'Deutsch',
  'deu': 'Deutsch',
  'spa': 'Español',
  'por': 'Português',
  'lat': 'Latina',
  'rus': 'Русский',
  'jpn': '日本語',
  'chi': '中文',
  'zho': '中文',
  'dut': 'Nederlands',
  'nld': 'Nederlands',
};

String languageName(String code) =>
    _names[code.toLowerCase()] ?? code.toUpperCase();

const _iso3 = <String, String>{
  'en': 'eng',
  'it': 'ita',
  'fr': 'fre',
  'de': 'ger',
  'es': 'spa',
  'pt': 'por',
};

/// Open Library's three-letter code for a two-letter app language, if known.
String? iso3ForLanguage(String languageCode) =>
    _iso3[languageCode.toLowerCase()];

/// Languages offered as quick filters, in display order.
const filterLanguages = ['ita', 'eng', 'spa', 'fre', 'ger'];
