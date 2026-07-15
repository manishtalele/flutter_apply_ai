import 'package:flutter_apply_ai/core/errors/exceptions.dart';
import 'package:flutter_apply_ai/core/errors/failures.dart';

/// Translates a Data-layer [AppException] into a Domain-layer [Failure].
///
/// Because [AppException] is `sealed`, this switch is exhaustive — adding a new
/// exception type is a compile-time error until it is mapped here. This is the
/// single, DRY boundary where exceptions become failures.
Failure mapExceptionToFailure(AppException exception) {
  return switch (exception) {
    LocalDatabaseException() => DatabaseFailure(exception.message),
    CacheException() => CacheFailure(exception.message),
    SecureStorageException() => SecureStorageFailure(exception.message),
    NetworkException() => NetworkFailure(exception.message),
    ServerException() =>
      ServerFailure(exception.message, statusCode: exception.statusCode),
    AiException() => AiFailure(exception.message),
    GmailException() => GmailFailure(exception.message),
    AuthException() => AuthFailure(exception.message),
    NotFoundException() => NotFoundFailure(exception.message),
    ValidationException() => ValidationFailure(exception.message),
  };
}
