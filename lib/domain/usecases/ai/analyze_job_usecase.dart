import 'package:equatable/equatable.dart';
import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/domain/entities/job_posting.dart';
import 'package:flutter_apply_ai/domain/repositories/ai_repository.dart';
import 'package:flutter_apply_ai/domain/usecases/usecase.dart';

/// Parameters for [AnalyzeJobUseCase].
class AnalyzeJobParams extends Equatable {
  const AnalyzeJobParams({
    required this.rawText,
    this.candidateProfile = '',
  });

  final String rawText;
  final String candidateProfile;

  @override
  List<Object?> get props => <Object?>[rawText, candidateProfile];
}

/// Analyzes a pasted job description via the AI repository, producing a
/// structured [JobPosting] (extracted fields + generated email + match score).
class AnalyzeJobUseCase implements UseCase<JobPosting, AnalyzeJobParams> {
  const AnalyzeJobUseCase(this._aiRepository);

  final AiRepository _aiRepository;

  @override
  ResultFuture<JobPosting> call(AnalyzeJobParams params) {
    return _aiRepository.extractJobPosting(
      params.rawText,
      candidateProfile: params.candidateProfile,
    );
  }
}
