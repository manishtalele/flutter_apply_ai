import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/domain/repositories/resume_repository.dart';
import 'package:flutter_apply_ai/domain/usecases/usecase.dart';

/// Deletes a resume profile by id.
class DeleteResumeUseCase implements UseCase<void, String> {
  const DeleteResumeUseCase(this._repository);

  final ResumeRepository _repository;

  @override
  ResultVoid call(String id) => _repository.deleteResume(id);
}
