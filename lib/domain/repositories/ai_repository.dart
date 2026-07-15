import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/domain/entities/enums/reply_outcome.dart';
import 'package:flutter_apply_ai/domain/entities/job_posting.dart';

/// AI contract (Gemini). The interface lives in Domain; the implementation
/// (Module 9) lives in Data and hides Dio/Gemini entirely.
abstract interface class AiRepository {
  /// Analyzes a raw, pasted job description and returns the structured
  /// [JobPosting] (company, email, role, generated subject/body, match score,
  /// recommendation). [candidateProfile] describes the applicant (skills /
  /// experience) so the AI can compute a meaningful match score.
  ResultFuture<JobPosting> extractJobPosting(
    String rawText, {
    String candidateProfile = '',
  });

  /// Classifies an employer's reply email into a [ReplyOutcome] used to update
  /// the application's status.
  ResultFuture<ReplyOutcome> classifyReply(String emailBody);
}
