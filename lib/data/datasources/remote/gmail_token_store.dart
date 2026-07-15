import 'package:flutter_apply_ai/core/constants/storage_keys.dart';
import 'package:flutter_apply_ai/data/datasources/local/secure_storage_datasource.dart';

/// OAuth2 token set for the connected Gmail account.
class GmailTokens {
  const GmailTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiry,
  });

  final String accessToken;
  final String? refreshToken;
  final DateTime expiry;

  /// True when the access token has expired (with a 60s safety margin).
  bool get isExpired =>
      DateTime.now().isAfter(expiry.subtract(const Duration(seconds: 60)));

  GmailTokens copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiry,
  }) {
    return GmailTokens(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiry: expiry ?? this.expiry,
    );
  }
}

/// Persists the Gmail OAuth token set in secure storage.
abstract interface class GmailTokenStore {
  Future<GmailTokens?> read();
  Future<void> save(GmailTokens tokens);
  Future<void> clear();
  Future<bool> hasTokens();
}

class GmailTokenStoreImpl implements GmailTokenStore {
  GmailTokenStoreImpl({required SecureStorageDataSource secureStorage})
      : _secure = secureStorage;

  final SecureStorageDataSource _secure;

  @override
  Future<GmailTokens?> read() async {
    final String? accessToken =
        await _secure.read(StorageKeys.secureGmailAccessToken);
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }
    final String? refreshToken =
        await _secure.read(StorageKeys.secureGmailRefreshToken);
    final String? expiryRaw =
        await _secure.read(StorageKeys.secureGmailTokenExpiry);
    final int expiryMillis = int.tryParse(expiryRaw ?? '') ?? 0;

    return GmailTokens(
      accessToken: accessToken,
      refreshToken: (refreshToken?.isEmpty ?? true) ? null : refreshToken,
      expiry: DateTime.fromMillisecondsSinceEpoch(expiryMillis),
    );
  }

  @override
  Future<void> save(GmailTokens tokens) async {
    await _secure.write(StorageKeys.secureGmailAccessToken, tokens.accessToken);
    await _secure.write(
      StorageKeys.secureGmailTokenExpiry,
      tokens.expiry.millisecondsSinceEpoch.toString(),
    );
    final String? refreshToken = tokens.refreshToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _secure.write(StorageKeys.secureGmailRefreshToken, refreshToken);
    }
  }

  @override
  Future<void> clear() async {
    await _secure.delete(StorageKeys.secureGmailAccessToken);
    await _secure.delete(StorageKeys.secureGmailRefreshToken);
    await _secure.delete(StorageKeys.secureGmailTokenExpiry);
  }

  @override
  Future<bool> hasTokens() async {
    return _secure.contains(StorageKeys.secureGmailAccessToken);
  }
}
