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
