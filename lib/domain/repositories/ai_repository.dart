import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/domain/entities/enums/reply_outcome.dart';
import 'package:flutter_apply_ai/domain/entities/job_posting.dart';

/// AI contract (OpenAI). The interface lives in Domain; the implementation
/// (Module 9) lives in Data and hides Dio/OpenAI entirely.
abstract interface class AiRepository {
  /// Analyzes a raw, pasted job description and returns the structured
  /// [JobPosting] (company, email, role, generated subject/body, match score,
  /// recommendation). [candidateProfile] describes the applicant (skills /
  /// experience) so the AI can compute a meaningful match score.
  /// [candidateDetails] carries the structured facts a post may ask applicants
  /// to state (current location, CTC, notice period …) as label→value pairs;
  /// only filled-in details are passed, so the AI can answer what the post
  /// asks for without inventing anything.
  ResultFuture<JobPosting> extractJobPosting(
    String rawText, {
    String candidateProfile = '',
    Map<String, String> candidateDetails = const <String, String>{},
  });

  /// Classifies an employer's reply email into a [ReplyOutcome] used to update
  /// the application's status.
  ResultFuture<ReplyOutcome> classifyReply(String emailBody);
}
