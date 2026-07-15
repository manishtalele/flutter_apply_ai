import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/domain/entities/resume_profile.dart';
import 'package:flutter_apply_ai/domain/repositories/resume_repository.dart';
import 'package:flutter_apply_ai/domain/usecases/usecase.dart';

/// Loads all saved resume profiles.
class GetResumesUseCase implements UseCase<List<ResumeProfile>, NoParams> {
  const GetResumesUseCase(this._repository);

  final ResumeRepository _repository;

  @override
  ResultFuture<List<ResumeProfile>> call(NoParams params) =>
      _repository.getResumes();
}
