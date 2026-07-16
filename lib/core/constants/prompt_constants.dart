import 'package:flutter_apply_ai/core/utils/typedefs.dart';

/// OpenAI prompt templates and response schemas.
///
/// Structured output is enforced via the Responses API `text.format`
/// `json_schema` (strict) — the model returns schema-conformant JSON, never
/// free text requiring regex extraction. The system instruction sets role and
/// rules; the user content carries the actual data.
abstract final class PromptConstants {
  const PromptConstants._();

  // ── Job extraction ───────────────────────────────────────────────────
  static const String extractionSystemInstruction = '''
You are an expert technical recruiter and job-application assistant.
Given a raw job description (often copied from WhatsApp, LinkedIn, or email),
extract structured data and craft a tailored application email.

Rules:
- Extract the company, recipient email, role/title, location, required
  experience, and the list of required skills. If a field is genuinely absent,
  return an empty string (or empty array for skills) — never invent data.
- "email" must be the application/recipient email address found in the post. If
  no email is present, return an empty string.
- "subject" must be a concise, professional email subject line for applying to
  this role.
- "emailBody" must be a professional, personalized application email in valid
  HTML (use <p> paragraphs; no <html>/<body> wrapper). Reference the role and 1–2
  relevant skills. Keep it under 180 words. Do not fabricate the candidate's
  experience beyond what the provided candidate profile states. Do NOT add a
  sign-off or signature (no "Best regards, <name>", no contact details) — a
  signature block is appended automatically after your text.
- "matchScore" is an integer 0–100 measuring how well the candidate profile fits
  the role's required skills, experience, and location. If no candidate profile
  is provided, base the score on general seniority/skill alignment cues.
- "shouldApply" is true when matchScore >= 60 and a recipient email exists.
- "matchSummary" is a one-sentence justification for the score and recommendation.
Respond ONLY with JSON conforming to the provided schema.''';

  static String extractionUserContent({
    required String jobDescription,
    required String candidateProfile,
  }) {
    final String profile = candidateProfile.trim().isEmpty
        ? '(No candidate profile provided.)'
        : candidateProfile.trim();
    return '''
CANDIDATE PROFILE:
$profile

JOB DESCRIPTION:
$jobDescription''';
  }

  static const DataMap jobPostingResponseSchema = <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'company': <String, dynamic>{'type': 'string'},
      'email': <String, dynamic>{'type': 'string'},
      'role': <String, dynamic>{'type': 'string'},
      'location': <String, dynamic>{'type': 'string'},
      'experience': <String, dynamic>{'type': 'string'},
      'skills': <String, dynamic>{
        'type': 'array',
        'items': <String, dynamic>{'type': 'string'},
      },
      'subject': <String, dynamic>{'type': 'string'},
      'emailBody': <String, dynamic>{'type': 'string'},
      'matchScore': <String, dynamic>{'type': 'integer'},
      'shouldApply': <String, dynamic>{'type': 'boolean'},
      'matchSummary': <String, dynamic>{'type': 'string'},
    },
    'required': <String>[
      'company',
      'email',
      'role',
      'location',
      'experience',
      'skills',
      'subject',
      'emailBody',
      'matchScore',
      'shouldApply',
      'matchSummary',
    ],
    'additionalProperties': false,
  };

  // ── Reply classification (reply tracking) ─────────────────────────────
  static const String replySystemInstruction = '''
You classify an employer's reply to a job application into exactly one outcome:
- "interview": they want to schedule a call/interview or next steps.
- "selected": an offer or confirmation of selection.
- "rejected": a rejection or "not moving forward".
- "none": auto-reply, acknowledgement, or anything not clearly one of the above.
Respond ONLY with JSON conforming to the provided schema.''';

  static String replyUserContent(String emailBody) {
    return 'EMPLOYER REPLY:\n$emailBody';
  }

  static const DataMap replyResponseSchema = <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'outcome': <String, dynamic>{
        'type': 'string',
        'enum': <String>['interview', 'selected', 'rejected', 'none'],
      },
    },
    'required': <String>['outcome'],
    'additionalProperties': false,
  };
}
