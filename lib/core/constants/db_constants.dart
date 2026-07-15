/// SQLite identifiers — database name/version, table names, and column names.
///
/// Single source of truth so data models, the schema definition (Module 7),
/// and query builders never hardcode a string. Column names use snake_case
/// (SQL convention); Dart fields stay camelCase and are mapped in the models.
abstract final class DbConstants {
  const DbConstants._();

  static const String databaseName = 'flutter_apply_ai.db';
  static const int databaseVersion = 1;

  // ── applications table ───────────────────────────────────────────────
  static const String tableApplications = 'applications';

  static const String colId = 'id';
  static const String colCompany = 'company';
  static const String colEmail = 'email';
  static const String colRole = 'role';
  static const String colLocation = 'location';
  static const String colSubject = 'subject';
  static const String colEmailBody = 'email_body';
  static const String colMatchScore = 'match_score';
  static const String colStatus = 'status';
  static const String colResumeName = 'resume_name';
  static const String colGmailMessageId = 'gmail_message_id';
  static const String colGmailThreadId = 'gmail_thread_id';
  static const String colAppliedAt = 'applied_at';
  static const String colUpdatedAt = 'updated_at';
}
