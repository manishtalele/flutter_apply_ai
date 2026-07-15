import 'dart:convert';

import 'package:flutter_apply_ai/core/constants/storage_keys.dart';
import 'package:flutter_apply_ai/core/errors/exceptions.dart';
import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Non-secret settings persistence backed by SharedPreferences. Stores the
/// settings bundle and the resume-profile list as JSON. Secrets (API key,
/// OAuth tokens) are handled separately by [SecureStorageDataSource].
abstract interface class SettingsLocalDataSource {
  Future<Map<String, dynamic>> readSettingsBundle();
  Future<void> writeSettingsBundle(Map<String, dynamic> bundle);
  Future<List<Map<String, dynamic>>> readResumes();
  Future<void> writeResumes(List<Map<String, dynamic>> resumes);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  SettingsLocalDataSourceImpl({
    required SharedPreferences preferences,
    required AppLogger logger,
  })  : _preferences = preferences,
        _logger = logger;

  final SharedPreferences _preferences;
  final AppLogger _logger;

  @override
  Future<Map<String, dynamic>> readSettingsBundle() async {
    final String? raw = _preferences.getString(StorageKeys.settingsBundle);
    if (raw == null || raw.isEmpty) {
      return <String, dynamic>{};
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{};
    } catch (error, stackTrace) {
      _logger.e('Failed to decode settings bundle', error, stackTrace);
      throw CacheException('Corrupt settings data.', error);
    }
  }

  @override
  Future<void> writeSettingsBundle(Map<String, dynamic> bundle) async {
    try {
      await _preferences.setString(
        StorageKeys.settingsBundle,
        jsonEncode(bundle),
      );
    } catch (error, stackTrace) {
      _logger.e('Failed to persist settings bundle', error, stackTrace);
      throw CacheException('Unable to save settings.', error);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> readResumes() async {
    final String? raw = _preferences.getString(StorageKeys.resumesList);
    if (raw == null || raw.isEmpty) {
      return <Map<String, dynamic>>[];
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
      }
      return <Map<String, dynamic>>[];
    } catch (error, stackTrace) {
      _logger.e('Failed to decode resumes list', error, stackTrace);
      throw CacheException('Corrupt resume data.', error);
    }
  }

  @override
  Future<void> writeResumes(List<Map<String, dynamic>> resumes) async {
    try {
      await _preferences.setString(
        StorageKeys.resumesList,
        jsonEncode(resumes),
      );
    } catch (error, stackTrace) {
      _logger.e('Failed to persist resumes list', error, stackTrace);
      throw CacheException('Unable to save resumes.', error);
    }
  }
}
