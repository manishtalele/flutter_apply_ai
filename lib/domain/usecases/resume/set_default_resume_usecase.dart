import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/domain/repositories/resume_repository.dart';
import 'package:flutter_apply_ai/domain/usecases/usecase.dart';

/// Marks a resume profile as the default.
class SetDefaultResumeUseCase implements UseCase<void, String> {
  const SetDefaultResumeUseCase(this._repository);

  final ResumeRepository _repository;

  @override
  ResultVoid call(String id) => _repository.setDefault(id);
}
