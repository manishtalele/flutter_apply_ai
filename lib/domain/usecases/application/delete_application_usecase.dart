import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/domain/repositories/application_repository.dart';
import 'package:flutter_apply_ai/domain/usecases/usecase.dart';

/// Deletes an application by its id.
class DeleteApplicationUseCase implements UseCase<void, int> {
  const DeleteApplicationUseCase(this._repository);

  final ApplicationRepository _repository;

  @override
  ResultVoid call(int id) => _repository.delete(id);
}
