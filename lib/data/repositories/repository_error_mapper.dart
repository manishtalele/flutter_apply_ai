import 'package:dartz/dartz.dart';
import 'package:flutter_apply_ai/core/errors/exceptions.dart';
import 'package:flutter_apply_ai/core/errors/failure_mapper.dart';
import 'package:flutter_apply_ai/core/errors/failures.dart';
import 'package:flutter_apply_ai/core/utils/app_logger.dart';

/// Shared error-handling for repository implementations.
///
/// [guard] runs a data operation and converts the outcome into
/// `Either<Failure, T>`: typed [AppException]s are mapped via
/// [mapExceptionToFailure]; anything unexpected becomes an [UnknownFailure]
/// and is logged. This removes duplicated try/catch from every repo method.
mixin RepositoryErrorMapper {
  AppLogger get logger;

  Future<Either<Failure, T>> guard<T>(Future<T> Function() action) async {
    try {
      final T value = await action();
      return Right<Failure, T>(value);
    } on AppException catch (exception) {
      return Left<Failure, T>(mapExceptionToFailure(exception));
    } catch (error, stackTrace) {
      logger.e('Unexpected repository failure', error, stackTrace);
      return Left<Failure, T>(UnknownFailure(error.toString()));
    }
  }
}
