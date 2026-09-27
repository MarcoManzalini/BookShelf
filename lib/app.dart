import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/home_widget/reading_widget_sync.dart';
import 'features/library/presentation/bloc/library_bloc.dart';
import 'features/profile/presentation/cubit/theme_cubit.dart';
import 'features/reminders/data/loan_reminders.dart';
import 'features/reminders/data/reading_reminders.dart';
import 'l10n/gen/app_localizations.dart';

class BookShelfApp extends StatefulWidget {
  const BookShelfApp({super.key});

  @override
  State<BookShelfApp> createState() => _BookShelfAppState();
}

class _BookShelfAppState extends State<BookShelfApp>
    with WidgetsBindingObserver {
  final _authBloc = getIt<AuthBloc>();
  final _libraryBloc = getIt<LibraryBloc>();
  final _themeCubit = getIt<ThemeCubit>();
  final _router = getIt<GoRouter>();
  final _reminders = getIt<ReadingReminders>();
  // Created now so it follows the library from the first load.
  final _loanReminders = getIt<LoanReminders>();
  final _widget = getIt<ReadingWidgetSync>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_authBloc.state.user != null) {
      _libraryBloc.add(const LibraryStarted());
      _reminders.refresh();
      _widget.refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Coming back to the app is a good moment to sync: the connection may have
  /// returned while it was in the background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _authBloc.state.user != null) {
      _libraryBloc.add(const LibraryRefreshRequested());
      // A new day may have started: the reminder text depends on it.
      _reminders.refresh();
      _widget.refresh();
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
          // Reminders speak about this account's reading.
          state.user == null ? _reminders.clear() : _reminders.refresh();
          if (state.user == null) {
            _loanReminders.clear();
            _widget.clear();
          } else {
            _widget.refresh();
          }
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
