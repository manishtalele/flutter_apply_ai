/// Typed exceptions thrown by the Data layer (datasources).
///
/// Exceptions never cross into the Domain or Presentation layers: repository
/// implementations catch these and translate them into `Failure`s (Module 8).
/// The hierarchy is `sealed` so that translation code can switch over it
/// exhaustively.
sealed class AppException implements Exception {
  const AppException(this.message, [this.cause]);

  /// Human-readable, developer-facing description.
  final String message;

  /// The underlying error/exception that triggered this one, if any.
  final Object? cause;

  @override
  String toString() =>
      '$runtimeType: $message${cause == null ? '' : ' (cause: $cause)'}';
}

/// SQLite / local database failure. Named `LocalDatabaseException` to avoid
/// colliding with sqflite's own `DatabaseException`.
class LocalDatabaseException extends AppException {
  const LocalDatabaseException(super.message, [super.cause]);
}

/// SharedPreferences read/write/serialization failure.
class CacheException extends AppException {
  const CacheException(super.message, [super.cause]);
}

/// Secure storage (credential manager / keychain) failure.
class SecureStorageException extends AppException {
  const SecureStorageException(super.message, [super.cause]);
}

/// Transport-level networking failure (timeout, no connection, cancelled).
class NetworkException extends AppException {
  const NetworkException(super.message, [super.cause]);
}

/// Non-2xx HTTP response from a remote API.
class ServerException extends AppException {
  const ServerException(String message, {this.statusCode, Object? cause})
      : super(message, cause);

  final int? statusCode;
}

/// Gemini AI request failed or returned an unparseable response.
class AiException extends AppException {
  const AiException(super.message, [super.cause]);
}

/// Gmail API operation failed.
class GmailException extends AppException {
  const GmailException(super.message, [super.cause]);
}

/// OAuth2 authentication/authorization failure (not connected, denied,
/// refresh failed).
class AuthException extends AppException {
  const AuthException(super.message, [super.cause]);
}

/// A record was expected but not found.
class NotFoundException extends AppException {
  const NotFoundException(super.message, [super.cause]);
}

/// Input failed validation before an operation was attempted.
class ValidationException extends AppException {
  const ValidationException(super.message, [super.cause]);
}
