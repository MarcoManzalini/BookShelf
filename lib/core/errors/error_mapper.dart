import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'failure.dart';

/// Converts any thrown object into a [Failure]. Repositories call this so
/// Blocs only ever see [Failure].
Failure mapError(Object error) {
  if (error is Failure) return error;
  if (error is DioException) return _mapDio(error);
  if (error is AuthRetryableFetchException) {
    return const Failure(FailureCode.network);
  }
  if (error is AuthException) return _mapAuth(error);
  if (error is PostgrestException) return _mapPostgrest(error);
  if (error is StorageException) {
    return Failure(FailureCode.server, message: error.message);
  }
  if (error is SocketException) return const Failure(FailureCode.network);
  if (error is TimeoutException) return const Failure(FailureCode.timeout);
  // package:http's ClientException (thrown by supabase on connectivity loss)
  // is not a direct dependency, so it is matched by type name.
  if (error.runtimeType.toString() == 'ClientException') {
    return const Failure(FailureCode.network);
  }
  return Failure(FailureCode.unknown, message: error.toString());
}

Failure _mapDio(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const Failure(FailureCode.timeout);
    case DioExceptionType.connectionError:
      return const Failure(FailureCode.network);
    case DioExceptionType.badResponse:
      final status = e.response?.statusCode;
      if (status == 404) return const Failure(FailureCode.notFound);
      if (status == 429) return const Failure(FailureCode.rateLimited);
      return Failure(FailureCode.server, message: 'HTTP $status');
    case DioExceptionType.cancel:
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      if (e.error is SocketException) {
        return const Failure(FailureCode.network);
      }
      return Failure(FailureCode.unknown, message: e.message);
  }
}

Failure _mapAuth(AuthException e) {
  switch (e.code) {
    case 'invalid_credentials':
      return const Failure(FailureCode.invalidCredentials);
    case 'email_not_confirmed':
      return const Failure(FailureCode.emailNotConfirmed);
    case 'user_already_exists':
    case 'email_exists':
      return const Failure(FailureCode.userAlreadyExists);
    case 'weak_password':
      return const Failure(FailureCode.weakPassword);
    case 'over_request_rate_limit':
    case 'over_email_send_rate_limit':
      return const Failure(FailureCode.rateLimited);
    case 'session_not_found':
    case 'refresh_token_not_found':
      return const Failure(FailureCode.unauthorized);
  }
  final message = e.message.toLowerCase();
  if (message.contains('invalid login credentials')) {
    return const Failure(FailureCode.invalidCredentials);
  }
  if (message.contains('already registered')) {
    return const Failure(FailureCode.userAlreadyExists);
  }
  if (message.contains('not confirmed')) {
    return const Failure(FailureCode.emailNotConfirmed);
  }
  return Failure(FailureCode.server, message: e.message);
}

Failure _mapPostgrest(PostgrestException e) {
  if (e.code == 'PGRST116') return const Failure(FailureCode.notFound);
  if (e.code == '42501' || e.code == 'PGRST301') {
    return const Failure(FailureCode.unauthorized);
  }
  return Failure(FailureCode.server, message: e.message);
}
