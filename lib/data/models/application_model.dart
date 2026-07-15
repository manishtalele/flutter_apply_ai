import 'package:flutter_apply_ai/core/constants/db_constants.dart';
import 'package:flutter_apply_ai/domain/entities/application.dart';
import 'package:flutter_apply_ai/domain/entities/enums/application_status.dart';

/// Data-layer DTO for [Application]. Maps to/from the `applications` SQLite
/// row. Column keys come from [DbConstants]; timestamps are epoch millis;
/// status is stored as its stable [ApplicationStatus.value] string.
class ApplicationModel extends Application {
  const ApplicationModel({
    required super.company,
    required super.email,
    required super.role,
    required super.location,
    required super.subject,
    required super.emailBody,
    required super.matchScore,
    required super.status,
    required super.resumeName,
    required super.appliedAt,
    required super.updatedAt,
    super.id,
    super.gmailMessageId,
    super.gmailThreadId,
  });

  factory ApplicationModel.fromEntity(Application entity) {
    return ApplicationModel(
      id: entity.id,
      company: entity.company,
      email: entity.email,
      role: entity.role,
      location: entity.location,
      subject: entity.subject,
      emailBody: entity.emailBody,
      matchScore: entity.matchScore,
      status: entity.status,
      resumeName: entity.resumeName,
      gmailMessageId: entity.gmailMessageId,
      gmailThreadId: entity.gmailThreadId,
      appliedAt: entity.appliedAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory ApplicationModel.fromMap(Map<String, Object?> map) {
    return ApplicationModel(
      id: map[DbConstants.colId] as int?,
      company: (map[DbConstants.colCompany] as String?) ?? '',
      email: (map[DbConstants.colEmail] as String?) ?? '',
      role: (map[DbConstants.colRole] as String?) ?? '',
      location: (map[DbConstants.colLocation] as String?) ?? '',
      subject: (map[DbConstants.colSubject] as String?) ?? '',
      emailBody: (map[DbConstants.colEmailBody] as String?) ?? '',
      matchScore: (map[DbConstants.colMatchScore] as num?)?.toInt() ?? 0,
      status: ApplicationStatus.fromValue(
        (map[DbConstants.colStatus] as String?) ?? ApplicationStatus.applied.value,
      ),
      resumeName: (map[DbConstants.colResumeName] as String?) ?? '',
      gmailMessageId: map[DbConstants.colGmailMessageId] as String?,
      gmailThreadId: map[DbConstants.colGmailThreadId] as String?,
      appliedAt: DateTime.fromMillisecondsSinceEpoch(
        (map[DbConstants.colAppliedAt] as num?)?.toInt() ?? 0,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (map[DbConstants.colUpdatedAt] as num?)?.toInt() ?? 0,
      ),
    );
  }

  /// Serializes to a SQLite row. The primary key is omitted when `null` so
  /// SQLite assigns an autoincrement id on insert.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) DbConstants.colId: id,
      DbConstants.colCompany: company,
      DbConstants.colEmail: email,
      DbConstants.colRole: role,
      DbConstants.colLocation: location,
      DbConstants.colSubject: subject,
      DbConstants.colEmailBody: emailBody,
      DbConstants.colMatchScore: matchScore,
      DbConstants.colStatus: status.value,
      DbConstants.colResumeName: resumeName,
      DbConstants.colGmailMessageId: gmailMessageId,
      DbConstants.colGmailThreadId: gmailThreadId,
      DbConstants.colAppliedAt: appliedAt.millisecondsSinceEpoch,
      DbConstants.colUpdatedAt: updatedAt.millisecondsSinceEpoch,
    };
  }
}
