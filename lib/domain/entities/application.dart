import 'package:equatable/equatable.dart';
import 'package:flutter_apply_ai/domain/entities/enums/application_status.dart';

/// A persisted job application record (one row in the `applications` table).
///
/// [id] is `null` before the row is inserted and populated by SQLite's
/// autoincrement afterwards. Gmail identifiers are retained so the
/// reply-tracking feature can correlate the sent message with its thread.
class Application extends Equatable {
  const Application({
    required this.company,
    required this.email,
    required this.role,
    required this.location,
    required this.subject,
    required this.emailBody,
    required this.matchScore,
    required this.status,
    required this.resumeName,
    required this.appliedAt,
    required this.updatedAt,
    this.id,
    this.gmailMessageId,
    this.gmailThreadId,
  });

  final int? id;
  final String company;
  final String email;
  final String role;
  final String location;
  final String subject;
  final String emailBody;
  final int matchScore;
  final ApplicationStatus status;
  final String resumeName;
  final String? gmailMessageId;
  final String? gmailThreadId;
  final DateTime appliedAt;
  final DateTime updatedAt;

  bool get isPersisted => id != null;

  Application copyWith({
    int? id,
    String? company,
    String? email,
    String? role,
    String? location,
    String? subject,
    String? emailBody,
    int? matchScore,
    ApplicationStatus? status,
    String? resumeName,
    String? gmailMessageId,
    String? gmailThreadId,
    DateTime? appliedAt,
    DateTime? updatedAt,
  }) {
    return Application(
      id: id ?? this.id,
      company: company ?? this.company,
      email: email ?? this.email,
      role: role ?? this.role,
      location: location ?? this.location,
      subject: subject ?? this.subject,
      emailBody: emailBody ?? this.emailBody,
      matchScore: matchScore ?? this.matchScore,
      status: status ?? this.status,
      resumeName: resumeName ?? this.resumeName,
      gmailMessageId: gmailMessageId ?? this.gmailMessageId,
      gmailThreadId: gmailThreadId ?? this.gmailThreadId,
      appliedAt: appliedAt ?? this.appliedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        company,
        email,
        role,
        location,
        subject,
        emailBody,
        matchScore,
        status,
        resumeName,
        gmailMessageId,
        gmailThreadId,
        appliedAt,
        updatedAt,
      ];
}
