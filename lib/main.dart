import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/di/injection.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final env = await Env.load();
  if (!env.isConfigured) {
    runApp(const _MissingConfigApp());
    return;
  }

  await Supabase.initialize(
    url: env.supabaseUrl,
    // Accepts the legacy anon JWT or the new sb_publishable_ key.
    publishableKey: env.supabaseAnonKey,
  );
  await configureDependencies();
  getIt<AuthBloc>().add(const AuthStarted());

  runApp(const BookShelfApp());
}

/// Shown when `.env` is missing or empty, so the failure is explicit.
class _MissingConfigApp extends StatelessWidget {
  const _MissingConfigApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.settings_suggest_outlined, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    'Configurazione mancante / Missing configuration',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Copia .env.example in .env e imposta SUPABASE_URL e '
                    'SUPABASE_ANON_KEY.\n'
                    'Copy .env.example to .env and set SUPABASE_URL and '
                    'SUPABASE_ANON_KEY.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
