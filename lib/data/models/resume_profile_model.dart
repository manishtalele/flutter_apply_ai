import 'package:flutter_apply_ai/domain/entities/resume_profile.dart';

/// Data-layer DTO for [ResumeProfile]. Resume profiles are persisted as a JSON
/// list in SharedPreferences (small, structured config — not a good fit for a
/// SQL table). Timestamps are stored as epoch milliseconds for locale-safe
/// round-tripping.
class ResumeProfileModel extends ResumeProfile {
  const ResumeProfileModel({
    required super.id,
    required super.label,
    required super.filePath,
    required super.isDefault,
    required super.createdAt,
  });

  factory ResumeProfileModel.fromJson(Map<String, dynamic> json) {
    return ResumeProfileModel(
      id: (json['id'] as String?) ?? '',
      label: (json['label'] as String?) ?? '',
      filePath: (json['filePath'] as String?) ?? '',
      isDefault: (json['isDefault'] as bool?) ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  factory ResumeProfileModel.fromEntity(ResumeProfile entity) {
    return ResumeProfileModel(
      id: entity.id,
      label: entity.label,
      filePath: entity.filePath,
      isDefault: entity.isDefault,
      createdAt: entity.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'label': label,
      'filePath': filePath,
      'isDefault': isDefault,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
