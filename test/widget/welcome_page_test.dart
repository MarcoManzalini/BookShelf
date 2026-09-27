import 'package:bookshelf/core/router/app_router.dart';
import 'package:bookshelf/core/theme/app_theme.dart';
import 'package:bookshelf/features/auth/presentation/pages/welcome_page.dart';
import 'package:bookshelf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Future<GoRouter> pumpWelcome(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.welcome,
      routes: [
        GoRoute(
          path: AppRoutes.welcome,
          builder: (_, __) => const WelcomePage(),
        ),
        GoRoute(
          path: AppRoutes.register,
          builder: (_, __) => const Text('register-page'),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (_, __) => const Text('login-page'),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        locale: const Locale('it'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('shows the name, the tagline and both actions', (tester) async {
    await pumpWelcome(tester);

    expect(find.text('BookShelf'), findsOneWidget);
    expect(find.text('Inizia'), findsOneWidget);
    expect(find.text('Ho già un account'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swiping moves between the three slides', (tester) async {
    await pumpWelcome(tester);
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.text('Trova e organizza'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.text('Leggi e misura'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  Future<void> swipe(WidgetTester tester) async {
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
  }

  testWidgets('"I already have an account" opens the login page',
      (tester) async {
    await pumpWelcome(tester);

    await tester.tap(find.text('Ho già un account'));
    await tester.pumpAndSettle();

    expect(find.text('login-page'), findsOneWidget);
  });

  testWidgets('Inizia starts the tour and Avanti goes on', (tester) async {
    await pumpWelcome(tester);

    await tester.tap(find.text('Inizia'));
    await tester.pumpAndSettle();
    expect(find.text('Trova e organizza'), findsOneWidget);
    expect(find.text('Avanti'), findsOneWidget);
    expect(find.text('Salta'), findsOneWidget);

    await tester.tap(find.text('Avanti'));
    await tester.pumpAndSettle();
    expect(find.text('Leggi e misura'), findsOneWidget);
  });

  testWidgets('Salta jumps to the last slide', (tester) async {
    await pumpWelcome(tester);
    await swipe(tester);

    await tester.tap(find.text('Salta'));
    await tester.pumpAndSettle();

    expect(find.text('Leggi e misura'), findsOneWidget);
  });

  testWidgets('the last slide offers sign-up and sign-in', (tester) async {
    await pumpWelcome(tester);
    await swipe(tester);
    await swipe(tester);

    await tester.tap(find.text('Inizia'));
    await tester.pumpAndSettle();
    expect(find.text('register-page'), findsOneWidget);
  });

  testWidgets('Accedi on the last slide opens the login page', (tester) async {
    await pumpWelcome(tester);
    await swipe(tester);
    await swipe(tester);

    await tester.tap(find.text('Accedi'));
    await tester.pumpAndSettle();
    expect(find.text('login-page'), findsOneWidget);
  });
}
