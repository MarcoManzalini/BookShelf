import 'dart:async';

import 'package:bookshelf/core/errors/failure.dart';
import 'package:bookshelf/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:bookshelf/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bookshelf/features/auth/domain/entities/auth_snapshot.dart';
import 'package:bookshelf/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late MockAuthRemoteDataSource remote;
  late AuthRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(supabase.OAuthProvider.apple));

  setUp(() {
    remote = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(remote);
  });

  test('starts the Supabase Apple OAuth flow', () async {
    when(() => remote.signInWithOAuth(any())).thenAnswer((_) async => true);

    await repository.signInWithProvider(SocialProvider.apple);

    verify(() => remote.signInWithOAuth(supabase.OAuthProvider.apple))
        .called(1);
  });

  test('throws a Failure when the browser cannot be opened', () {
    when(() => remote.signInWithOAuth(any())).thenAnswer((_) async => false);

    expect(
      repository.signInWithProvider(SocialProvider.apple),
      throwsA(isA<Failure>()),
    );
  });

  test('a failed OAuth callback does not end the auth stream', () async {
    final controller = StreamController<supabase.AuthState>();
    addTearDown(controller.close);
    when(() => remote.authStateChanges).thenAnswer((_) => controller.stream);

    final snapshots = <AuthSnapshot>[];
    final done = Completer<void>();
    repository.changes.listen(
      (s) {
        snapshots.add(s);
        if (!done.isCompleted) done.complete();
      },
      onError: (_) => fail('error must not reach listeners'),
    );

    controller
      ..addError(const supabase.AuthException('access_denied'))
      ..add(const supabase.AuthState(supabase.AuthChangeEvent.signedOut, null));
    await done.future;

    expect(snapshots, [const AuthSnapshot.unauthenticated()]);
  });
}
