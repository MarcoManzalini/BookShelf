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
