import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/auth_snapshot.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/book_details/presentation/pages/book_details_page.dart';
import '../../features/library/presentation/pages/library_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/library_io/presentation/pages/import_export_page.dart';
import '../../features/recap/domain/reading_recap.dart';
import '../../features/recap/presentation/pages/recap_page.dart';
import '../../features/scanner/presentation/pages/scan_page.dart';
import '../../features/stats/presentation/pages/stats_page.dart';
import '../../features/search/domain/entities/book.dart';
import '../../features/search/domain/entities/explore_genre.dart';
import '../../features/search/domain/entities/explore_section.dart';
import '../../features/search/presentation/pages/explore_genre_page.dart';
import '../../features/search/presentation/pages/explore_section_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import 'book_open_page.dart';
import 'go_router_refresh_stream.dart';
import 'main_shell.dart';

abstract final class AppRoutes {
  static const welcome = '/auth/welcome';
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const forgotPassword = '/auth/forgot-password';
  static const resetPassword = '/auth/reset-password';
  static const library = '/library';
  static const search = '/search';
  static const profile = '/profile';
  static const scan = '/scan';
  static const stats = '/stats';
  static const data = '/data';

  static String bookDetails(String id) => '/book/$id';

  /// The yearly recap, or the monthly one when [month] is given.
  static String recap(int year, [int? month]) =>
      month == null ? '/recap/$year' : '/recap/$year/$month';

  /// The search tab with [query] already typed.
  static String searchFor(String query) =>
      '$search?q=${Uri.encodeQueryComponent(query)}';
  static String preview(String externalId) => '/preview/$externalId';
  static String exploreSection(String name) => '/explore/$name';
  static String exploreGenre(String name) => '/explore/genre/$name';
}

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.library,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) =>
        authRedirect(authBloc.state.status, state.matchedLocation),
    routes: [
      // Supabase deep links (email confirmation / recovery) arrive as `/`.
      GoRoute(path: '/', redirect: (_, __) => AppRoutes.library),
      GoRoute(
        path: '/login-callback',
        redirect: (_, __) => AppRoutes.library,
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, __) => const WelcomePage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (_, __) => const ResetPasswordPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.library,
                builder: (_, __) => const LibraryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                builder: (_, state) =>
                    SearchPage(initialQuery: state.uri.queryParameters['q']),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (_, __) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/book/:id',
        pageBuilder: (_, state) => BookOpenPage.forState(
          state,
          child:
              BookDetailsPage.library(userBookId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.data,
        builder: (_, __) => const ImportExportPage(),
      ),
      GoRoute(
        path: AppRoutes.stats,
        builder: (_, __) => const StatsPage(),
      ),
      GoRoute(
        path: '/recap/:year',
        redirect: (_, state) =>
            int.tryParse(state.pathParameters['year']!) == null
                ? AppRoutes.stats
                : null,
        builder: (_, state) => RecapPage(
          period: RecapPeriod.year(int.parse(state.pathParameters['year']!)),
        ),
      ),
      GoRoute(
        path: '/recap/:year/:month',
        redirect: (_, state) {
          final year = int.tryParse(state.pathParameters['year']!);
          final month = int.tryParse(state.pathParameters['month']!);
          return year == null || month == null || month < 1 || month > 12
              ? AppRoutes.stats
              : null;
        },
        builder: (_, state) => RecapPage(
          period: RecapPeriod.month(
            int.parse(state.pathParameters['year']!),
            int.parse(state.pathParameters['month']!),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.scan,
        builder: (_, __) => const ScanPage(),
      ),
      GoRoute(
        path: '/explore/genre/:genre',
        redirect: (_, state) => ExploreGenre.values
                .any((g) => g.name == state.pathParameters['genre'])
            ? null
            : AppRoutes.search,
        builder: (_, state) => ExploreGenrePage(
          genre: ExploreGenre.values.byName(state.pathParameters['genre']!),
        ),
      ),
      GoRoute(
        path: '/explore/:section',
        redirect: (_, state) => ExploreSection.values
                .any((s) => s.name == state.pathParameters['section'])
            ? null
            : AppRoutes.search,
        builder: (_, state) => ExploreSectionPage(
          section:
              ExploreSection.values.byName(state.pathParameters['section']!),
        ),
      ),
      GoRoute(
        path: '/preview/:externalId',
        redirect: (_, state) => state.extra is Book ? null : AppRoutes.search,
        pageBuilder: (_, state) => BookOpenPage.forState(
          state,
          child: BookDetailsPage.preview(book: state.extra! as Book),
        ),
      ),
    ],
  );
}

/// Pure guard logic, exposed for testing.
String? authRedirect(AuthStatus status, String location) {
  final inAuthArea = location.startsWith('/auth');
  switch (status) {
    case AuthStatus.passwordRecovery:
      return location == AppRoutes.resetPassword
          ? null
          : AppRoutes.resetPassword;
    case AuthStatus.unauthenticated:
      final allowed = inAuthArea && location != AppRoutes.resetPassword;
      return allowed ? null : AppRoutes.welcome;
    case AuthStatus.authenticated:
      return inAuthArea ? AppRoutes.library : null;
  }
}
