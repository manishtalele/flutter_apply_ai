import 'package:equatable/equatable.dart';

/// Domain-facing error type. Repositories return `Either<Failure, T>`; the UI
/// switches/renders on these rather than on raw exceptions. Every [Failure]
/// carries a user-presentable [message].
abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

/// Local SQLite database failure.
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

/// SharedPreferences read/write/serialization failure.
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Secure storage (credentials) failure.
class SecureStorageFailure extends Failure {
  const SecureStorageFailure(super.message);
}

/// Transport-level networking failure.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Non-2xx response from a remote API.
class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode});

  final int? statusCode;

  @override
  List<Object?> get props => <Object?>[message, statusCode];
}

/// Gemini AI failure (request failed / unparseable response).
class AiFailure extends Failure {
  const AiFailure(super.message);
}

/// Gmail API failure.
class GmailFailure extends Failure {
  const GmailFailure(super.message);
}

/// OAuth2 authentication/authorization failure.
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// A requested record did not exist.
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

/// Input validation failure.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Unexpected/unclassified failure (defensive catch-all).
class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
