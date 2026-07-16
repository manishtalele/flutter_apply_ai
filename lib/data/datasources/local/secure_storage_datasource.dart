import 'package:flutter_apply_ai/core/errors/exceptions.dart';
import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure persistence for secrets (OpenAI API key, Gmail OAuth tokens),
/// backed by the OS credential store (Windows Credential Manager / macOS
/// Keychain / libsecret). Values are read/written by the [StorageKeys]
/// `secure*` keys.
abstract interface class SecureStorageDataSource {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<bool> contains(String key);
}

class SecureStorageDataSourceImpl implements SecureStorageDataSource {
  SecureStorageDataSourceImpl({
    required FlutterSecureStorage storage,
    required AppLogger logger,
  })  : _storage = storage,
        _logger = logger;

  final FlutterSecureStorage _storage;
  final AppLogger _logger;

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (error, stackTrace) {
      _logger.e('Secure read failed for "$key"', error, stackTrace);
      throw SecureStorageException('Unable to read secure value.', error);
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (error, stackTrace) {
      _logger.e('Secure write failed for "$key"', error, stackTrace);
      throw SecureStorageException('Unable to store secure value.', error);
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (error, stackTrace) {
      _logger.e('Secure delete failed for "$key"', error, stackTrace);
      throw SecureStorageException('Unable to delete secure value.', error);
    }
  }

  @override
  Future<bool> contains(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (error, stackTrace) {
      _logger.e('Secure contains failed for "$key"', error, stackTrace);
      throw SecureStorageException('Unable to query secure store.', error);
    }
  }
}
