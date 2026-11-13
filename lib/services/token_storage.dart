import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StoredTokens {
  final String? accessToken;
  final String? refreshToken;
  final String? idToken;
  final DateTime? expiresAt;

  const StoredTokens({
    this.accessToken,
    this.refreshToken,
    this.idToken,
    this.expiresAt,
  });

  bool get hasRefreshToken => refreshToken != null && refreshToken!.isNotEmpty;

  bool get isAccessTokenValid {
    if (accessToken == null || accessToken!.isEmpty || expiresAt == null) {
      return false;
    }
    return expiresAt!.isAfter(DateTime.now().add(const Duration(seconds: 60)));
  }
}

class TokenStorage {
  static const _kAccessToken = 'oidc_access_token';
  static const _kRefreshToken = 'oidc_refresh_token';
  static const _kIdToken = 'oidc_id_token';
  static const _kExpiresAt = 'oidc_expires_at';
  static const _kBiometricEnabled = 'biometric_lock_enabled';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    String? idToken,
    DateTime? expiresAt,
  }) async {
    await _storage.write(key: _kAccessToken, value: accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: _kRefreshToken, value: refreshToken);
    }
    if (idToken != null && idToken.isNotEmpty) {
      await _storage.write(key: _kIdToken, value: idToken);
    }
    if (expiresAt != null) {
      await _storage.write(key: _kExpiresAt, value: expiresAt.toUtc().toIso8601String());
    }
  }

  Future<StoredTokens> readTokens() async {
    final accessToken = await _storage.read(key: _kAccessToken);
    final refreshToken = await _storage.read(key: _kRefreshToken);
    final idToken = await _storage.read(key: _kIdToken);
    final expiresRaw = await _storage.read(key: _kExpiresAt);
    final expiresAt = expiresRaw != null ? DateTime.tryParse(expiresRaw)?.toLocal() : null;

    return StoredTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      idToken: idToken,
      expiresAt: expiresAt,
    );
  }

  Future<bool> hasSavedSession() async {
    final refresh = await _storage.read(key: _kRefreshToken);
    final access = await _storage.read(key: _kAccessToken);
    return (refresh != null && refresh.isNotEmpty) || (access != null && access.isNotEmpty);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _kBiometricEnabled, value: enabled ? 'true' : 'false');
  }

  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _kBiometricEnabled);
    return val != 'false';
  }

  Future<void> clear() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
    await _storage.delete(key: _kIdToken);
    await _storage.delete(key: _kExpiresAt);
  }
}

