import 'package:flutter_apply_ai/core/constants/db_constants.dart';
import 'package:flutter_apply_ai/core/errors/exceptions.dart';
import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:flutter_apply_ai/data/datasources/local/app_database.dart';
import 'package:flutter_apply_ai/data/models/application_model.dart';
import 'package:flutter_apply_ai/domain/entities/enums/application_status.dart';
import 'package:sqflite/sqflite.dart';

/// Data-access contract for the `applications` table.
abstract interface class ApplicationLocalDataSource {
  Future<int> insert(ApplicationModel model);
  Future<void> update(ApplicationModel model);
  Future<void> deleteById(int id);
  Future<ApplicationModel?> getById(int id);

  /// Returns applications newest-first, optionally full-text-filtered by
  /// [search] (company/role/email/location) and/or by [status], paginated by
  /// [limit]/[offset].
  Future<List<ApplicationModel>> getAll({
    String? search,
    ApplicationStatus? status,
    int? limit,
    int? offset,
  });

  /// All applications previously sent to [email] (case-insensitive) — powers
  /// duplicate detection.
  Future<List<ApplicationModel>> findByEmail(String email);

  Future<int> countAll();
  Future<int> countAppliedSince(DateTime since);
  Future<int> countByStatus(ApplicationStatus status);
}

/// SQLite implementation. Every method funnels DB errors through
/// [LocalDatabaseException]; already-typed [AppException]s are rethrown
/// unchanged so callers see a stable exception surface.
class ApplicationLocalDataSourceImpl implements ApplicationLocalDataSource {
  ApplicationLocalDataSourceImpl({
    required AppDatabase database,
    required AppLogger logger,
  })  : _database = database,
        _logger = logger;

  final AppDatabase _database;
  final AppLogger _logger;

  @override
  Future<int> insert(ApplicationModel model) async {
    return _guard('insert', () async {
      final Database db = await _database.database;
      return db.insert(
        DbConstants.tableApplications,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    });
  }

  @override
  Future<void> update(ApplicationModel model) async {
    final int? id = model.id;
    if (id == null) {
      throw const ValidationException(
        'Cannot update an application without an id.',
      );
    }
    await _guard('update', () async {
      final Database db = await _database.database;
      final int affected = await db.update(
        DbConstants.tableApplications,
        model.toMap(),
        where: '${DbConstants.colId} = ?',
        whereArgs: <Object?>[id],
      );
      if (affected == 0) {
        throw NotFoundException('No application found with id $id.');
      }
    });
  }

  @override
  Future<void> deleteById(int id) async {
    await _guard('deleteById', () async {
      final Database db = await _database.database;
      await db.delete(
        DbConstants.tableApplications,
        where: '${DbConstants.colId} = ?',
        whereArgs: <Object?>[id],
      );
    });
  }

  @override
  Future<ApplicationModel?> getById(int id) async {
    return _guard('getById', () async {
      final Database db = await _database.database;
      final List<Map<String, Object?>> rows = await db.query(
        DbConstants.tableApplications,
        where: '${DbConstants.colId} = ?',
        whereArgs: <Object?>[id],
        limit: 1,
      );
      if (rows.isEmpty) {
        return null;
      }
      return ApplicationModel.fromMap(rows.first);
    });
  }

  @override
  Future<List<ApplicationModel>> getAll({
    String? search,
    ApplicationStatus? status,
    int? limit,
    int? offset,
  }) async {
    return _guard('getAll', () async {
      final Database db = await _database.database;
      final List<String> clauses = <String>[];
      final List<Object?> args = <Object?>[];

      final String? term = search?.trim();
      if (term != null && term.isNotEmpty) {
        final String like = '%$term%';
        clauses.add(
          '(${DbConstants.colCompany} LIKE ? '
          'OR ${DbConstants.colRole} LIKE ? '
          'OR ${DbConstants.colEmail} LIKE ? '
          'OR ${DbConstants.colLocation} LIKE ?)',
        );
        args.addAll(<Object?>[like, like, like, like]);
      }

      if (status != null) {
        clauses.add('${DbConstants.colStatus} = ?');
        args.add(status.value);
      }

      final List<Map<String, Object?>> rows = await db.query(
        DbConstants.tableApplications,
        where: clauses.isEmpty ? null : clauses.join(' AND '),
        whereArgs: args.isEmpty ? null : args,
        orderBy: '${DbConstants.colAppliedAt} DESC',
        limit: limit,
        offset: offset,
      );
      return rows.map(ApplicationModel.fromMap).toList(growable: false);
    });
  }

  @override
  Future<List<ApplicationModel>> findByEmail(String email) async {
    return _guard('findByEmail', () async {
      final Database db = await _database.database;
      final List<Map<String, Object?>> rows = await db.query(
        DbConstants.tableApplications,
        where: 'LOWER(${DbConstants.colEmail}) = ?',
        whereArgs: <Object?>[email.trim().toLowerCase()],
        orderBy: '${DbConstants.colAppliedAt} DESC',
      );
      return rows.map(ApplicationModel.fromMap).toList(growable: false);
    });
  }

  @override
  Future<int> countAll() async {
    return _guard('countAll', () async {
      final Database db = await _database.database;
      final List<Map<String, Object?>> result = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM ${DbConstants.tableApplications}',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    });
  }

  @override
  Future<int> countAppliedSince(DateTime since) async {
    return _guard('countAppliedSince', () async {
      final Database db = await _database.database;
      final List<Map<String, Object?>> result = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM ${DbConstants.tableApplications} '
        'WHERE ${DbConstants.colAppliedAt} >= ?',
        <Object?>[since.millisecondsSinceEpoch],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    });
  }

  @override
  Future<int> countByStatus(ApplicationStatus status) async {
    return _guard('countByStatus', () async {
      final Database db = await _database.database;
      final List<Map<String, Object?>> result = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM ${DbConstants.tableApplications} '
        'WHERE ${DbConstants.colStatus} = ?',
        <Object?>[status.value],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    });
  }

  /// Runs [action], rethrowing typed [AppException]s and wrapping anything
  /// else as a [LocalDatabaseException] with a log entry.
  Future<T> _guard<T>(String operation, Future<T> Function() action) async {
    try {
      return await action();
    } on AppException {
      rethrow;
    } catch (error, stackTrace) {
      _logger.e('Database operation "$operation" failed', error, stackTrace);
      throw LocalDatabaseException('Database operation failed.', error);
    }
  }
}
