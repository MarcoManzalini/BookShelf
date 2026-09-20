import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bookshelf/core/errors/failure.dart';
import 'package:bookshelf/features/auth/domain/entities/auth_snapshot.dart';
import 'package:bookshelf/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
    when(() => repository.current)
        .thenReturn(const AuthSnapshot.unauthenticated());
  });

  test('initial state reflects the persisted session', () {
    when(() => repository.current).thenReturn(
      const AuthSnapshot(AuthStatus.authenticated, testUser),
    );
    final bloc = AuthBloc(repository);
    expect(bloc.state.status, AuthStatus.authenticated);
    expect(bloc.state.user, testUser);
    addTearDown(bloc.close);
  });

  test('initial state is unauthenticated without a session', () {
    final bloc = AuthBloc(repository);
    expect(bloc.state.status, AuthStatus.unauthenticated);
    expect(bloc.state.user, isNull);
    addTearDown(bloc.close);
  });

  blocTest<AuthBloc, AuthState>(
    'AuthStarted mirrors onAuthStateChange events',
    setUp: () {
      when(() => repository.changes).thenAnswer(
        (_) => Stream.fromIterable(const [
          AuthSnapshot(AuthStatus.authenticated, testUser),
          AuthSnapshot(AuthStatus.passwordRecovery, testUser),
          AuthSnapshot.unauthenticated(),
        ]),
      );
    },
    build: () => AuthBloc(repository),
    act: (bloc) => bloc.add(const AuthStarted()),
    expect: () => const [
      AuthState(status: AuthStatus.authenticated, user: testUser),
      AuthState(status: AuthStatus.passwordRecovery, user: testUser),
      AuthState(status: AuthStatus.unauthenticated),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'AuthStarted ignores duplicate snapshots (e.g. token refresh)',
    setUp: () {
      when(() => repository.changes).thenAnswer(
        (_) => Stream.fromIterable(const [
          AuthSnapshot(AuthStatus.authenticated, testUser),
          AuthSnapshot(AuthStatus.authenticated, testUser),
        ]),
      );
    },
    build: () => AuthBloc(repository),
    act: (bloc) => bloc.add(const AuthStarted()),
    expect: () => const [
      AuthState(status: AuthStatus.authenticated, user: testUser),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'AuthLogoutRequested calls signOut; the stream drives the new state',
    setUp: () {
      when(() => repository.signOut()).thenAnswer((_) async {});
    },
    build: () => AuthBloc(repository),
    act: (bloc) => bloc.add(const AuthLogoutRequested()),
    expect: () => const <AuthState>[],
    verify: (_) => verify(() => repository.signOut()).called(1),
  );

  blocTest<AuthBloc, AuthState>(
    'AuthLogoutRequested surfaces a failure',
    setUp: () {
      when(() => repository.signOut())
          .thenThrow(const Failure(FailureCode.network));
    },
    build: () => AuthBloc(repository),
    act: (bloc) => bloc.add(const AuthLogoutRequested()),
    expect: () => const [
      AuthState(
        status: AuthStatus.unauthenticated,
        failure: Failure(FailureCode.network),
      ),
    ],
  );

  test('closing the bloc cancels the auth subscription', () async {
    final controller = StreamController<AuthSnapshot>.broadcast();
    when(() => repository.changes).thenAnswer((_) => controller.stream);
    final bloc = AuthBloc(repository)..add(const AuthStarted());
    await Future<void>.delayed(Duration.zero);
    expect(controller.hasListener, isTrue);
    await bloc.close();
    expect(controller.hasListener, isFalse);
    await controller.close();
  });
}
