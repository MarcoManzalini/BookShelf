import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  const AppConfig._();

  static const userAgent = 'BookShelf/1.0 (Flutter app; Open Library client)';
  static const openLibraryBaseUrl = 'https://openlibrary.org';
  static const authRedirectUrl = 'io.supabase.bookshelf://login-callback/';
  static const avatarsBucket = 'avatars';
  static const searchDebounce = Duration(milliseconds: 350);

  /// Shorter queries match too much of the catalogue to be worth a request.
  static const searchMinChars = 2;

  /// Google/Apple login is wired in the data layer but hidden until enabled.
  static const socialLoginEnabled = false;
}

class Env {
  const Env({required this.supabaseUrl, required this.supabaseAnonKey});

  /// Loads `.env`; a missing file yields an unconfigured [Env].
  static Future<Env> load() async {
    try {
      await dotenv.load();
    } catch (_) {
      return const Env(supabaseUrl: '', supabaseAnonKey: '');
    }
    return Env(
      supabaseUrl: dotenv.maybeGet('SUPABASE_URL')?.trim() ?? '',
      supabaseAnonKey: dotenv.maybeGet('SUPABASE_ANON_KEY')?.trim() ?? '',
    );
  }

  final String supabaseUrl;
  final String supabaseAnonKey;

  bool get isConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
