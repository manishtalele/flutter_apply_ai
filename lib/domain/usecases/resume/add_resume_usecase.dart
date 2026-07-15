import 'package:equatable/equatable.dart';
import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/domain/entities/resume_profile.dart';
import 'package:flutter_apply_ai/domain/repositories/resume_repository.dart';
import 'package:flutter_apply_ai/domain/usecases/usecase.dart';

/// Parameters for [AddResumeUseCase].
class AddResumeParams extends Equatable {
  const AddResumeParams({
    required this.label,
    required this.filePath,
    this.makeDefault = false,
  });

  final String label;
  final String filePath;
  final bool makeDefault;

  @override
  List<Object?> get props => <Object?>[label, filePath, makeDefault];
}

/// Adds a new resume profile.
class AddResumeUseCase implements UseCase<ResumeProfile, AddResumeParams> {
  const AddResumeUseCase(this._repository);

  final ResumeRepository _repository;

  @override
  ResultFuture<ResumeProfile> call(AddResumeParams params) {
    return _repository.addResume(
      label: params.label,
      filePath: params.filePath,
      makeDefault: params.makeDefault,
    );
  }
}
