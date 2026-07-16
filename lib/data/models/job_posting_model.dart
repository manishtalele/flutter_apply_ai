import 'package:flutter_apply_ai/domain/entities/job_posting.dart';

/// Data-layer DTO for [JobPosting]. Deserializes the structured JSON returned
/// by OpenAI. Parsing is defensive: the model coerces loose types (a number
/// as a string, skills as a comma-joined string, a bool as "true"/"1") into
/// the strict entity shape so a slightly-off AI response never crashes the UI.
class JobPostingModel extends JobPosting {
  const JobPostingModel({
    required super.company,
    required super.email,
    required super.role,
    required super.location,
    required super.experience,
    required super.skills,
    required super.subject,
    required super.emailBody,
    required super.matchScore,
    required super.shouldApply,
    super.matchSummary,
    super.phone,
  });

  factory JobPostingModel.fromJson(Map<String, dynamic> json) {
    return JobPostingModel(
      company: _asString(json['company']),
      email: _asString(json['email']),
      role: _asString(json['role']),
      location: _asString(json['location']),
      experience: _asString(json['experience']),
      skills: _asStringList(json['skills']),
      subject: _asString(json['subject']),
      emailBody: _asString(json['emailBody']),
      matchScore: _asScore(json['matchScore']),
      shouldApply: _asBool(json['shouldApply']),
      matchSummary: _asString(json['matchSummary']),
      phone: _asString(json['phone']),
    );
  }

  factory JobPostingModel.fromEntity(JobPosting entity) {
    return JobPostingModel(
      company: entity.company,
      email: entity.email,
      role: entity.role,
      location: entity.location,
      experience: entity.experience,
      skills: entity.skills,
      subject: entity.subject,
      emailBody: entity.emailBody,
      matchScore: entity.matchScore,
      shouldApply: entity.shouldApply,
      matchSummary: entity.matchSummary,
      phone: entity.phone,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'company': company,
      'email': email,
      'role': role,
      'location': location,
      'experience': experience,
      'skills': skills,
      'subject': subject,
      'emailBody': emailBody,
      'matchScore': matchScore,
      'shouldApply': shouldApply,
      'matchSummary': matchSummary,
      'phone': phone,
    };
  }

  static String _asString(Object? value) {
    if (value == null) {
      return '';
    }
    return value.toString().trim();
  }

  static int _asScore(Object? value) {
    if (value is num) {
      return value.toInt().clamp(0, 100);
    }
    if (value is String) {
      final int parsed = int.tryParse(value.trim()) ?? 0;
      return parsed.clamp(0, 100);
    }
    return 0;
  }

  static bool _asBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final String normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == 'yes' || normalized == '1';
    }
    return false;
  }

  static List<String> _asStringList(Object? value) {
    if (value is List) {
      return value
          .map((Object? e) => e?.toString().trim() ?? '')
          .where((String e) => e.isNotEmpty)
          .toList(growable: false);
    }
    if (value is String) {
      return value
          .split(',')
          .map((String e) => e.trim())
          .where((String e) => e.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }
}
