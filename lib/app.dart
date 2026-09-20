import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/library/presentation/bloc/library_bloc.dart';
import 'features/profile/presentation/cubit/theme_cubit.dart';
import 'l10n/gen/app_localizations.dart';

class BookShelfApp extends StatefulWidget {
  const BookShelfApp({super.key});

  @override
  State<BookShelfApp> createState() => _BookShelfAppState();
}

class _BookShelfAppState extends State<BookShelfApp> {
  final _authBloc = getIt<AuthBloc>();
  final _libraryBloc = getIt<LibraryBloc>();
  final _themeCubit = getIt<ThemeCubit>();
  final _router = getIt<GoRouter>();

  @override
  void initState() {
    super.initState();
    if (_authBloc.state.user != null) {
      _libraryBloc.add(const LibraryStarted());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<LibraryBloc>.value(value: _libraryBloc),
        BlocProvider<ThemeCubit>.value(value: _themeCubit),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            previous.user?.id != current.user?.id,
        listener: (context, state) {
          _libraryBloc.add(
            state.user == null
                ? const LibraryCleared()
                : const LibraryStarted(),
          );
        },
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp.router(
              onGenerateTitle: (context) =>
                  AppLocalizations.of(context).appTitle,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              routerConfig: _router,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              // Italian is the default when the device language is unsupported.
              localeResolutionCallback: (locale, supported) {
                for (final s in supported) {
                  if (s.languageCode == locale?.languageCode) return s;
                }
                return const Locale('it');
              },
            );
          },
        ),
      ),
    );
  }
}
