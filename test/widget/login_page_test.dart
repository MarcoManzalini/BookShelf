import 'package:bloc_test/bloc_test.dart';
import 'package:bookshelf/core/errors/failure.dart';
import 'package:bookshelf/core/utils/request_status.dart';
import 'package:bookshelf/features/auth/domain/repositories/auth_repository.dart';
import 'package:bookshelf/features/auth/presentation/cubit/auth_form_cubit.dart';
import 'package:bookshelf/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/pump_app.dart';

class MockAuthFormCubit extends MockCubit<AuthFormState>
    implements AuthFormCubit {}

void main() {
  late MockAuthFormCubit cubit;

  setUp(() {
    cubit = MockAuthFormCubit();
    when(() => cubit.state).thenReturn(const AuthFormState());
    when(() => cubit.signIn(any(), any())).thenAnswer((_) async {});
    when(() => cubit.signInWithProvider(any())).thenAnswer((_) async {});
  });

  setUpAll(() => registerFallbackValue(SocialProvider.apple));

  Future<void> pumpLogin(WidgetTester tester) {
    return tester.pumpApp(
      BlocProvider<AuthFormCubit>.value(value: cubit, child: const LoginView()),
    );
  }

  testWidgets('shows validation errors and does not submit empty form',
      (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Accedi'));
    await tester.pump();

    expect(find.text('Inserisci un indirizzo email valido'), findsNothing);
    expect(find.text('Campo obbligatorio'), findsNWidgets(2));
    verifyNever(() => cubit.signIn(any(), any()));
  });

  testWidgets('rejects a malformed email', (tester) async {
    await pumpLogin(tester);

    await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
    await tester.enterText(find.byType(TextFormField).last, 'secret1');
    await tester.tap(find.widgetWithText(FilledButton, 'Accedi'));
    await tester.pump();

    expect(find.text('Inserisci un indirizzo email valido'), findsOneWidget);
    verifyNever(() => cubit.signIn(any(), any()));
  });

  testWidgets('submits valid credentials', (tester) async {
    await pumpLogin(tester);

    await tester.enterText(
      find.byType(TextFormField).first,
      'reader@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'secret1');
    await tester.tap(find.widgetWithText(FilledButton, 'Accedi'));
    await tester.pump();

    verify(() => cubit.signIn('reader@example.com', 'secret1')).called(1);
  });

  testWidgets('shows a snackbar with the localized failure', (tester) async {
    whenListen(
      cubit,
      Stream.fromIterable(const [
        AuthFormState(status: RequestStatus.loading),
        AuthFormState(
          status: RequestStatus.failure,
          failure: Failure(FailureCode.invalidCredentials),
        ),
      ]),
      initialState: const AuthFormState(),
    );
    await pumpLogin(tester);
    await tester.pump();
    await tester.pump();

    expect(find.text('Email o password non corrette.'), findsOneWidget);
  });

  testWidgets('renders in English when the locale is English', (tester) async {
    await tester.pumpApp(
      BlocProvider<AuthFormCubit>.value(value: cubit, child: const LoginView()),
      locale: const Locale('en'),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('starts Apple sign-in', (tester) async {
    await pumpLogin(tester);

    await tester.ensureVisible(find.text('Continua con Apple'));
    await tester.tap(find.text('Continua con Apple'));

    verify(() => cubit.signInWithProvider(SocialProvider.apple)).called(1);
  });

  testWidgets('disables the Apple button while a request runs', (tester) async {
    when(() => cubit.state)
        .thenReturn(const AuthFormState(status: RequestStatus.loading));
    await pumpLogin(tester);

    await tester.ensureVisible(find.text('Continua con Apple'));
    await tester.tap(find.text('Continua con Apple'));

    verifyNever(() => cubit.signInWithProvider(any()));
  });
}
