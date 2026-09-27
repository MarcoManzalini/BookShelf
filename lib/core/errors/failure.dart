import 'package:equatable/equatable.dart';

enum FailureCode {
  network,
  timeout,
  server,
  notFound,
  unauthorized,
  invalidCredentials,
  emailNotConfirmed,
  userAlreadyExists,
  weakPassword,
  rateLimited,

  /// The database lacks a column, table or value the app uses: the update
  /// script (supabase/update.sql) has not been run yet.
  outdatedDatabase,
  unknown,
}

class Failure extends Equatable implements Exception {
  const Failure(this.code, {this.message});

  final FailureCode code;
  final String? message;

  @override
  List<Object?> get props => [code, message];

  @override
  String toString() => 'Failure($code${message == null ? '' : ': $message'})';
}
