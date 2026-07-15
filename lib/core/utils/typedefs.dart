import 'package:dartz/dartz.dart';
import 'package:flutter_apply_ai/core/errors/failures.dart';

/// A computation that succeeds with [T] or fails with a [Failure].
typedef ResultFuture<T> = Future<Either<Failure, T>>;

/// A side-effecting computation that succeeds with no value or fails.
typedef ResultVoid = Future<Either<Failure, void>>;

/// A synchronous success-or-failure result.
typedef Result<T> = Either<Failure, T>;

/// Loosely-typed JSON map (deserialization boundary).
typedef DataMap = Map<String, dynamic>;
