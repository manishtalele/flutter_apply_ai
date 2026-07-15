import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/domain/entities/resume_profile.dart';

/// Contract for managing the user's resume profiles (multiple named resumes,
/// one marked default). Backed by SharedPreferences JSON.
abstract interface class ResumeRepository {
  ResultFuture<List<ResumeProfile>> getResumes();

  /// Adds a resume. If [makeDefault] is true (or this is the first resume) it
  /// becomes the default and any previous default is cleared. Returns the
  /// created profile.
  ResultFuture<ResumeProfile> addResume({
    required String label,
    required String filePath,
    bool makeDefault = false,
  });

  ResultFuture<void> deleteResume(String id);

  ResultFuture<void> setDefault(String id);

  /// The default resume, or `null` if none exists.
  ResultFuture<ResumeProfile?> getDefault();
}
