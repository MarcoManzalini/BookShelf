import 'package:bookshelf/core/errors/error_mapper.dart';
import 'package:bookshelf/core/errors/failure.dart';
import 'package:bookshelf/core/router/app_router.dart';
import 'package:bookshelf/core/utils/cover_url.dart';
import 'package:bookshelf/features/auth/domain/entities/auth_snapshot.dart';
import 'package:bookshelf/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/fixtures.dart';
import '../helpers/mocks.dart';

void main() {
  group('authRedirect', () {
    test('unauthenticated users are sent to the welcome page', () {
      expect(
        authRedirect(AuthStatus.unauthenticated, AppRoutes.library),
        AppRoutes.welcome,
      );
      expect(
        authRedirect(AuthStatus.unauthenticated, '/book/abc'),
        AppRoutes.welcome,
      );
    });

    group('shared shelf links', () {
      test('unauthenticated on a shared shelf remembers it and goes to welcome',
          () {
        final pending = PendingDeepLink();
        expect(
          authRedirect(
            AuthStatus.unauthenticated,
            AppRoutes.sharedShelf('abc'),
            pending: pending,
          ),
          AppRoutes.welcome,
        );
        expect(pending.location, '/shared-shelf/abc');
      });

      test('authenticated in the auth area resumes the pending shared shelf',
          () {
        final pending = PendingDeepLink()..location = '/shared-shelf/abc';
        expect(
          authRedirect(
            AuthStatus.authenticated,
            AppRoutes.login,
            pending: pending,
          ),
          '/shared-shelf/abc',
        );
        expect(pending.location, isNull);
      });

      test('authenticated in the auth area without pending goes to library',
          () {
        expect(
          authRedirect(
            AuthStatus.authenticated,
            AppRoutes.login,
            pending: PendingDeepLink(),
          ),
          AppRoutes.library,
        );
      });

      test('the link host as a path segment is remembered normalized', () {
        final pending = PendingDeepLink();
        authRedirect(
          AuthStatus.unauthenticated,
          '/shelf/shared-shelf/abc',
          pending: pending,
        );
        expect(pending.location, '/shared-shelf/abc');
      });

      test('a login completed outside the auth pages still resumes once', () {
        final pending = PendingDeepLink()..location = '/shared-shelf/abc';
        expect(
          authRedirect(
            AuthStatus.authenticated,
            AppRoutes.library,
            pending: pending,
          ),
          '/shared-shelf/abc',
        );
        expect(pending.location, isNull);
        expect(
          authRedirect(
            AuthStatus.authenticated,
            AppRoutes.library,
            pending: pending,
          ),
          isNull,
        );
      });

      test('a link without a token opens the shared shelf page', () {
        final auth = MockAuthRepository();
        when(() => auth.current)
            .thenReturn(const AuthSnapshot(AuthStatus.authenticated, testUser));
        final router = createRouter(AuthBloc(auth));
        addTearDown(router.dispose);
        for (final path in ['/shared-shelf', '/shelf/shared-shelf']) {
          final match = router.configuration.findMatch(Uri.parse(path));
          expect(match.isError, isFalse, reason: path);
        }
      });

      test('pending ignores locations other than shared shelves', () {
        final pending = PendingDeepLink();
        authRedirect(AuthStatus.unauthenticated, '/book/x', pending: pending);
        expect(pending.location, isNull);
      });
    });

    test('unauthenticated users can use the auth pages', () {
      expect(
        authRedirect(AuthStatus.unauthenticated, AppRoutes.welcome),
        isNull,
      );
      expect(authRedirect(AuthStatus.unauthenticated, AppRoutes.login), isNull);
      expect(
        authRedirect(AuthStatus.unauthenticated, AppRoutes.register),
        isNull,
      );
      expect(
        authRedirect(AuthStatus.unauthenticated, AppRoutes.forgotPassword),
        isNull,
      );
    });

    test('reset-password is not reachable without a recovery session', () {
      expect(
        authRedirect(AuthStatus.unauthenticated, AppRoutes.resetPassword),
        AppRoutes.welcome,
      );
    });

    test('authenticated users skip the auth pages', () {
      expect(
        authRedirect(AuthStatus.authenticated, AppRoutes.login),
        AppRoutes.library,
      );
      expect(authRedirect(AuthStatus.authenticated, AppRoutes.search), isNull);
    });

    test('password recovery is forced onto the reset page', () {
      expect(
        authRedirect(AuthStatus.passwordRecovery, AppRoutes.library),
        AppRoutes.resetPassword,
      );
      expect(
        authRedirect(AuthStatus.passwordRecovery, AppRoutes.resetPassword),
        isNull,
      );
    });
  });

  group('mapError', () {
    test('a missing column or enum value means the database is outdated', () {
      for (final e in const [
        PostgrestException(
          message: 'column user_books.format does not exist',
          code: '42703',
        ),
        PostgrestException(
          message: "Could not find the 'pace' column of 'user_books'",
          code: 'PGRST204',
        ),
        PostgrestException(
          message: 'invalid input value for enum reading_status: "paused"',
          code: '22P02',
        ),
        PostgrestException(
          message: 'Could not find the function public.get_shared_shelf',
          code: 'PGRST202',
        ),
      ]) {
        expect(mapError(e).code, FailureCode.outdatedDatabase);
      }
      expect(
        mapError(
          const PostgrestException(
            message: 'invalid input syntax for type uuid',
            code: '22P02',
          ),
        ).code,
        FailureCode.server,
      );
    });

    test('maps Dio connection errors to network', () {
      final failure = mapError(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError,
        ),
      );
      expect(failure.code, FailureCode.network);
    });

    test('maps Dio timeouts and HTTP statuses', () {
      expect(
        mapError(
          DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.receiveTimeout,
          ),
        ).code,
        FailureCode.timeout,
      );
      Failure status(int code) => mapError(
            DioException(
              requestOptions: RequestOptions(),
              type: DioExceptionType.badResponse,
              response: Response(
                requestOptions: RequestOptions(),
                statusCode: code,
              ),
            ),
          );
      expect(status(404).code, FailureCode.notFound);
      expect(status(429).code, FailureCode.rateLimited);
      expect(status(500).code, FailureCode.server);
    });

    test('passes Failures through unchanged', () {
      const failure = Failure(FailureCode.weakPassword);
      expect(mapError(failure), same(failure));
    });
  });

  group('resizeCoverUrl', () {
    const url = 'https://covers.openlibrary.org/b/id/1-L.jpg?default=false';

    test('swaps the Open Library size suffix', () {
      expect(
        resizeCoverUrl(url, CoverSize.small),
        'https://covers.openlibrary.org/b/id/1-S.jpg?default=false',
      );
    });

    test('leaves other hosts untouched', () {
      expect(
        resizeCoverUrl('https://example.com/a-L.jpg', CoverSize.small),
        'https://example.com/a-L.jpg',
      );
    });
  });
}
