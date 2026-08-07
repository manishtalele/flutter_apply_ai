import 'package:equatable/equatable.dart';
import 'package:flutter_apply_ai/domain/entities/enums/candidate_detail.dart';

/// The structured result of AI-analyzing a raw, pasted job description.
///
/// This is a transient, in-memory entity (it becomes an [Application] only
/// once the user chooses to apply). All fields are non-null; missing data from
/// the AI is represented by empty strings / empty lists, never `null`, so the
/// UI never has to null-check.
class JobPosting extends Equatable {
  const JobPosting({
    required this.company,
    required this.email,
    required this.role,
    required this.location,
    required this.experience,
    required this.skills,
    required this.subject,
    required this.emailBody,
    required this.matchScore,
    required this.shouldApply,
    this.matchSummary = '',
    this.phone = '',
    this.requestedDetails = const <CandidateDetail>[],
  });

  final String company;
  final String email;
  final String role;
  final String location;
  final String experience;
  final List<String> skills;
  final String subject;
  final String emailBody;

  /// Contact / WhatsApp phone number extracted from the post ('' if none).
  final String phone;

  /// AI-computed fit score, 0–100.
  final int matchScore;

  /// AI recommendation on whether the user should apply.
  final bool shouldApply;

  /// Short natural-language justification for [matchScore] / [shouldApply].
  final String matchSummary;

  /// The candidate details this post explicitly asks the applicant to state,
  /// whether or not the app had a value for them. Reported by the AI so the UI
  /// can warn about the ones the user has not filled in — those are silently
  /// left out of the subject and body rather than guessed.
  final List<CandidateDetail> requestedDetails;

  /// Whether a recipient email address was extracted.
  bool get hasRecipient => email.trim().isNotEmpty;

  /// Whether a contact phone number was extracted.
  bool get hasPhone => phone.trim().isNotEmpty;

  /// Whether the posting has the minimum data required to send an application.
  bool get isSendable =>
      hasRecipient && subject.trim().isNotEmpty && emailBody.trim().isNotEmpty;

  JobPosting copyWith({
    String? company,
    String? email,
    String? role,
    String? location,
    String? experience,
    List<String>? skills,
    String? subject,
    String? emailBody,
    int? matchScore,
    bool? shouldApply,
    String? matchSummary,
    String? phone,
    List<CandidateDetail>? requestedDetails,
  }) {
    return JobPosting(
      company: company ?? this.company,
      email: email ?? this.email,
      role: role ?? this.role,
      location: location ?? this.location,
      experience: experience ?? this.experience,
      skills: skills ?? this.skills,
      subject: subject ?? this.subject,
      emailBody: emailBody ?? this.emailBody,
      matchScore: matchScore ?? this.matchScore,
      shouldApply: shouldApply ?? this.shouldApply,
      matchSummary: matchSummary ?? this.matchSummary,
      phone: phone ?? this.phone,
      requestedDetails: requestedDetails ?? this.requestedDetails,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        company,
        email,
        role,
        location,
        experience,
        skills,
        subject,
        emailBody,
        matchScore,
        shouldApply,
        matchSummary,
        phone,
        requestedDetails,
      ];
}
