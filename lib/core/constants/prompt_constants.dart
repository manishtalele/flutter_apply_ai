import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/domain/entities/enums/candidate_detail.dart';

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
- "phone" must be the contact/WhatsApp phone number found in the post, kept in
  its original form including the country code if present (e.g. "+91 9655573339").
  Return an empty string if no phone number is present.
- "subject" must be a concise, professional email subject line for applying to
  this role. Job posts often dictate the subject (e.g. "Mail Subject: Android
  Developer | Experience | Current Location"). When they do:
  - Keep the post's exact wording, field order, and separators.
  - Treat every field name in that template as a PLACEHOLDER TO FILL IN, never
    as text to copy. Replace each one with the candidate's real value from
    CANDIDATE DETAILS. For the example above with 3.5 years' experience and a
    Pune location, the subject is "Android Developer | 3.5 years | Pune, India"
    — NOT "Android Developer | Experience | Current Location". Shipping the
    placeholder words unfilled is a failure.
  - Words that are literal template text rather than a field — the role name, a
    job ID, "Application for", a company name — stay exactly as written.
  - If the template asks for a field the candidate details do not provide, drop
    that segment along with its separator. Never guess a value, and never leave
    the placeholder word standing in its place.
  - The same substitution rule applies to any detail the post wants in the
    subject, not just experience and location (CTC, notice period, and so on).
  If the post dictates no subject, write your own concise one naming the role.
- "emailBody" must be a complete, professional, personalized application email
  in valid HTML (use <p> paragraphs and <br> for line breaks; no <html>/<body>
  wrapper). Structure it as:
    1. A greeting addressed to the hiring team / named recruiter if the post
       names one.
    2. An opening line stating the exact role being applied for (and the
       requisition/job ID if the post has one).
    3. One or two paragraphs mapping the candidate's actual experience and
       skills onto the specific requirements named in the post — cite concrete
       skills from the post that the candidate genuinely has.
    4. The requested-details block described below, when applicable.
    5. A closing line noting the attached resume and inviting next steps.
  Aim for 150–250 words. Do not fabricate the candidate's experience, skills,
  or credentials beyond what the candidate profile and candidate details state.
  Do NOT add a sign-off or signature (no "Best regards, <name>", no contact
  details) — a signature block is appended automatically after your text.
- REQUESTED DETAILS — read the job post carefully for details it explicitly
  asks applicants to share or mention in their mail (common examples: current
  location, preferred/willing location, total experience, relevant experience,
  current CTC, expected CTC, notice period / availability to join, current
  company, reason for change, portfolio or GitHub link). For every such detail:
  - If the CANDIDATE DETAILS section below provides it, state it explicitly in
    the email as a labelled line, grouped into one block near the end of the
    body, e.g.
    <p><b>As requested:</b><br>Current Location: Pune, India<br>Notice Period:
    30 days</p>
  - If the post asks for a detail that is NOT in the candidate details or the
    profile, simply omit that line. NEVER guess, estimate, or invent a
    location, salary figure, notice period, or years of experience.
  - Use only the labels the post actually asks for. If the post asks for
    nothing specific, omit the block entirely.
- "requestedDetails" must list which of these tracked details the post asks the
  applicant to provide, anywhere — in the subject line, in the body, or in a
  list of instructions: currentLocation, totalExperience, currentCtc,
  expectedCtc, noticePeriod. Use an empty array when the post asks for none.
  Report a detail here whenever the post asks for it, INCLUDING when the
  candidate details do not provide it and you therefore had to leave it out —
  this list is what tells the user which details are missing, so omitting one
  hides the gap from them. Only report what the post genuinely asks for; do not
  add a detail merely because the candidate happens to have supplied it.
- "matchScore" is an integer 0–100 measuring how well the candidate profile fits
  the role's required skills, experience, and location. If no candidate profile
  is provided, base the score on general seniority/skill alignment cues.
- "shouldApply" is true when matchScore >= 60 and a recipient email exists.
- "matchSummary" is a one-sentence justification for the score and recommendation.
Respond ONLY with JSON conforming to the provided schema.''';

  /// Builds the user turn: the candidate's free-text profile, their structured
  /// details (only the ones they filled in), then the raw job description.
  ///
  /// [candidateDetails] is deliberately a label→value map rather than prose so
  /// the model can echo a requested detail verbatim, and so an unfilled field
  /// is simply absent — leaving nothing for it to guess from.
  static String extractionUserContent({
    required String jobDescription,
    required String candidateProfile,
    Map<String, String> candidateDetails = const <String, String>{},
  }) {
    final String profile = candidateProfile.trim().isEmpty
        ? '(No candidate profile provided.)'
        : candidateProfile.trim();
    final String details = candidateDetails.isEmpty
        ? '(No structured candidate details provided — do not invent any.)'
        : candidateDetails.entries
            .map((MapEntry<String, String> e) => '- ${e.key}: ${e.value}')
            .join('\n');
    return '''
CANDIDATE PROFILE:
$profile

CANDIDATE DETAILS (use verbatim; anything not listed here is unknown):
$details

JOB DESCRIPTION:
$jobDescription''';
  }

  // `final` rather than `const`: the requestedDetails enum is derived from
  // [CandidateDetail] so the schema can never drift from the Dart enum.
  static final DataMap jobPostingResponseSchema = <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'company': <String, dynamic>{'type': 'string'},
      'email': <String, dynamic>{'type': 'string'},
      'phone': <String, dynamic>{'type': 'string'},
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
      // Constrained to the CandidateDetail tokens, so the response maps
      // straight onto the enum with no string matching on our side.
      'requestedDetails': <String, dynamic>{
        'type': 'array',
        'items': <String, dynamic>{
          'type': 'string',
          'enum': CandidateDetail.allValues,
        },
      },
    },
    'required': <String>[
      'company',
      'email',
      'phone',
      'role',
      'location',
      'experience',
      'skills',
      'subject',
      'emailBody',
      'matchScore',
      'shouldApply',
      'matchSummary',
      'requestedDetails',
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
