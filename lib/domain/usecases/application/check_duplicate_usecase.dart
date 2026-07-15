import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/domain/entities/application.dart';
import 'package:flutter_apply_ai/domain/repositories/application_repository.dart';
import 'package:flutter_apply_ai/domain/usecases/usecase.dart';

/// Returns prior applications sent to the given recipient email, so the UI can
/// warn before applying again. An empty list means no duplicate.
class CheckDuplicateUseCase implements UseCase<List<Application>, String> {
  const CheckDuplicateUseCase(this._repository);

  final ApplicationRepository _repository;

  @override
  ResultFuture<List<Application>> call(String email) =>
      _repository.findByEmail(email);
}
