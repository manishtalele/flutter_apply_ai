import 'package:equatable/equatable.dart';
import 'package:flutter_apply_ai/core/utils/typedefs.dart';

/// Base contract for a single business action.
///
/// A use case takes a [Params] object and returns a `ResultFuture<Type>`. This
/// uniform shape lets controllers invoke any use case identically and keeps
/// business rules out of the Presentation layer.
abstract class UseCase<T, Params> {
  const UseCase();

  ResultFuture<T> call(Params params);
}

/// Marker for use cases that take no parameters.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => <Object?>[];
}
