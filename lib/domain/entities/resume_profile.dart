import 'package:equatable/equatable.dart';

/// A named resume the user can attach to applications (e.g. "Flutter Resume",
/// "Java Resume"). One profile may be marked as the default.
class ResumeProfile extends Equatable {
  const ResumeProfile({
    required this.id,
    required this.label,
    required this.filePath,
    required this.isDefault,
    required this.createdAt,
  });

  /// Stable unique identifier (referenced by `AppSettings.defaultResumeId`).
  final String id;

  /// Display name shown in Settings and the resume picker.
  final String label;

  /// Absolute path to the resume file on disk.
  final String filePath;

  final bool isDefault;
  final DateTime createdAt;

  /// File name (with extension) derived from [filePath]; handles both Windows
  /// (`\`) and POSIX (`/`) separators.
  String get fileName =>
      filePath.split(RegExp(r'[\\/]')).where((String s) => s.isNotEmpty).last;

  ResumeProfile copyWith({
    String? id,
    String? label,
    String? filePath,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return ResumeProfile(
      id: id ?? this.id,
      label: label ?? this.label,
      filePath: filePath ?? this.filePath,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        label,
        filePath,
        isDefault,
        createdAt,
      ];
}
