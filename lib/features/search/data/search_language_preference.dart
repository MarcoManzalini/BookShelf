import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the language filter the reader chose for searches.
class SearchLanguagePreference {
  const SearchLanguagePreference(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'search_language';

  /// Three-letter code, or null for "all languages".
  String? load() => _prefs.getString(_key);

  Future<void> save(String? language) =>
      language == null ? _prefs.remove(_key) : _prefs.setString(_key, language);
}
