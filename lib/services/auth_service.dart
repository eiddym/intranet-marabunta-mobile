import 'package:flutter_appauth/flutter_appauth.dart';
import '../config/auth_config.dart';
import 'biometric_service.dart';
import 'token_storage.dart';

class AuthService {
  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final TokenStorage _storage = TokenStorage();
  final BiometricService _biometrics = BiometricService();

  Future<bool> hasSavedSession() => _storage.hasSavedSession();

  Future<bool> loginWithPkce() async {
    final result = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        AuthConfig.clientId,
        AuthConfig.redirectUri,
        discoveryUrl: AuthConfig.discoveryUrl,
        scopes: AuthConfig.scopes,
        preferEphemeralSession: false,
      ),
    );

    if (result == null || result.accessToken == null || result.accessToken!.isEmpty) {
      return false;
    }

    await _storage.saveTokens(
      accessToken: result.accessToken!,
      refreshToken: result.refreshToken,
      idToken: result.idToken,
      expiresAt: result.accessTokenExpirationDateTime,
    );
    return true;
  }

  Future<bool> unlockSavedSessionWithBiometrics() async {
    final hasSession = await _storage.hasSavedSession();
    if (!hasSession) {
      return false;
    }

    final bioEnabled = await _storage.isBiometricEnabled();
    if (bioEnabled) {
      final verified = await _biometrics.authenticate(
        reason: 'Confirma tu identidad para acceder a Marabunta R.L.',
      );
      if (!verified) {
        return false;
      }
    }

    final token = await getValidAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> getValidAccessToken() async {
    final tokens = await _storage.readTokens();
    if (tokens.isAccessTokenValid) {
      return tokens.accessToken;
    }
    if (!tokens.hasRefreshToken) {
      return null;
    }
    return refreshAccessToken(tokens.refreshToken!);
  }

  Future<String?> refreshAccessToken([String? explicitRefreshToken]) async {
    final refreshToken = explicitRefreshToken ?? (await _storage.readTokens()).refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    try {
      final response = await _appAuth.token(
        TokenRequest(
          AuthConfig.clientId,
          AuthConfig.redirectUri,
          discoveryUrl: AuthConfig.discoveryUrl,
          refreshToken: refreshToken,
          scopes: AuthConfig.scopes,
          grantType: 'refresh_token',
        ),
      );

      if (response == null || response.accessToken == null || response.accessToken!.isEmpty) {
        return null;
      }

      await _storage.saveTokens(
        accessToken: response.accessToken!,
        refreshToken: response.refreshToken ?? refreshToken,
        idToken: response.idToken,
        expiresAt: response.accessTokenExpirationDateTime,
      );
      return response.accessToken;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.clear();
  }
}

