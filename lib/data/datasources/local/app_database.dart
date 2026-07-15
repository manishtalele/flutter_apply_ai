import 'dart:io';

import 'package:flutter_apply_ai/core/constants/db_constants.dart';
import 'package:flutter_apply_ai/core/errors/exceptions.dart';
import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Owns the single [Database] instance for the app.
///
/// The [DatabaseFactory] and file path are injectable so that unit tests can
/// run against an in-memory FFI database without the `path_provider` plugin.
/// In production, [main] installs `databaseFactoryFfi` as the global
/// [databaseFactory] and the DB lives in the OS application-support directory.
class AppDatabase {
  AppDatabase({
    required AppLogger logger,
    DatabaseFactory? factory,
    String? pathOverride,
  })  : _logger = logger,
        _factory = factory ?? databaseFactory,
        _pathOverride = pathOverride;

  final AppLogger _logger;
  final DatabaseFactory _factory;
  final String? _pathOverride;

  Database? _database;

  /// Returns the open database, opening (and creating/migrating) it lazily on
  /// first access.
  Future<Database> get database async {
    final Database? existing = _database;
    if (existing != null && existing.isOpen) {
      return existing;
    }
    final Database opened = await _open();
    _database = opened;
    return opened;
  }

  Future<Database> _open() async {
    try {
      final String path = await _resolvePath();
      _logger.i('Opening SQLite database at: $path');
      return await _factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: DbConstants.databaseVersion,
          onConfigure: _onConfigure,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    } catch (error, stackTrace) {
      _logger.e('Failed to open the database', error, stackTrace);
      throw LocalDatabaseException(
        'Unable to open the local database.',
        error,
      );
    }
  }

  Future<String> _resolvePath() async {
    final String? override = _pathOverride;
    if (override != null) {
      return override;
    }
    final Directory directory = await getApplicationSupportDirectory();
    return p.join(directory.path, DbConstants.databaseName);
  }

  Future<void> _onConfigure(Database db) async {
    // Enforce referential integrity for future related tables.
    await db.execute('PRAGMA foreign_keys = ON');
    // WAL improves read/write concurrency for a desktop file database; a busy
    // timeout avoids "database is locked" errors under brief contention.
    // (On an in-memory database WAL is a no-op, which is harmless.)
    await db.rawQuery('PRAGMA journal_mode = WAL');
    await db.execute('PRAGMA busy_timeout = 5000');
  }

  Future<void> _onCreate(Database db, int version) async {
    _logger.i('Creating database schema (version $version).');
    final Batch batch = db.batch();
    batch.execute(_createApplicationsTable);
    batch.execute(_createEmailIndex);
    batch.execute(_createStatusIndex);
    batch.execute(_createAppliedAtIndex);
    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logger.i('Migrating database from v$oldVersion to v$newVersion.');
    // No migrations yet (schema is at v1). Future schema changes append
    // guarded, ordered migration steps here, e.g.:
    //   if (oldVersion < 2) { await db.execute('ALTER TABLE ...'); }
  }

  /// Closes the underlying database (call on app shutdown / in tests).
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  static const String _createApplicationsTable = '''
    CREATE TABLE ${DbConstants.tableApplications} (
      ${DbConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${DbConstants.colCompany} TEXT NOT NULL,
      ${DbConstants.colEmail} TEXT NOT NULL,
      ${DbConstants.colRole} TEXT NOT NULL,
      ${DbConstants.colLocation} TEXT NOT NULL,
      ${DbConstants.colSubject} TEXT NOT NULL,
      ${DbConstants.colEmailBody} TEXT NOT NULL,
      ${DbConstants.colMatchScore} INTEGER NOT NULL,
      ${DbConstants.colStatus} TEXT NOT NULL,
      ${DbConstants.colResumeName} TEXT NOT NULL,
      ${DbConstants.colGmailMessageId} TEXT,
      ${DbConstants.colGmailThreadId} TEXT,
      ${DbConstants.colAppliedAt} INTEGER NOT NULL,
      ${DbConstants.colUpdatedAt} INTEGER NOT NULL
    )
  ''';

  static const String _createEmailIndex =
      'CREATE INDEX idx_applications_email '
      'ON ${DbConstants.tableApplications} (${DbConstants.colEmail})';

  static const String _createStatusIndex =
      'CREATE INDEX idx_applications_status '
      'ON ${DbConstants.tableApplications} (${DbConstants.colStatus})';

  static const String _createAppliedAtIndex =
      'CREATE INDEX idx_applications_applied_at '
      'ON ${DbConstants.tableApplications} (${DbConstants.colAppliedAt})';
}
