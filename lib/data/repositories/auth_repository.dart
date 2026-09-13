import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';
import '../api/wire.dart';
import 'repository_providers.dart';

/// Phone-OTP sign-in plus the rider→driver upgrade.
///
/// Every account starts as a `rider`. A new driver signs in with OTP, then
/// calls [registerAsDriver], which creates the driver profile server-side,
/// switches the account role, and returns a *new* token pair carrying
/// `role: driver` — the old tokens are still valid but authorize nothing
/// driver-only, so they are replaced immediately.
class AuthRepository {
  const AuthRepository(this._api);
  final ApiClient _api;

  /// POST /auth/otp/request
  Future<void> requestOtp(String phone) async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return;
    }
    await _api.postJson('/auth/otp/request', body: {'phone': phone}, auth: false);
  }

  /// POST /auth/otp/verify → tokens + role. Tokens are persisted here.
  Future<LoginResult> verifyOtp(String phone, String code) async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (code == '000000') throw const ApiException('UNAUTHORIZED', 'Invalid or expired OTP', statusCode: 401);
      const tokens = AuthTokens(accessToken: 'mock_access', refreshToken: 'mock_refresh');
      await _api.tokens.save(access: tokens.accessToken, refresh: tokens.refreshToken, userId: 'mock_user');
      return const LoginResult(tokens: tokens, userId: 'mock_user', isNewUser: false, role: 'driver', name: 'Tunde');
    }
    final j = await _api.postJson('/auth/otp/verify', body: {'phone': phone, 'code': code}, auth: false);
    final tokens = AuthTokens.fromJson(j);
    final userId = j['userId'] as String;
    await _api.tokens.save(access: tokens.accessToken, refresh: tokens.refreshToken, userId: userId);
    return LoginResult(
      tokens: tokens,
      userId: userId,
      isNewUser: j['isNewUser'] == true,
      role: _roleFromToken(tokens.accessToken),
      name: j['name']?.toString(),
    );
  }

  /// POST /drivers/register → { driver, accessToken, refreshToken }.
  /// Replaces the stored tokens with the driver-role pair.
  Future<DriverAccount> registerAsDriver() async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return const DriverAccount(id: 'mock_driver', userId: 'mock_user', status: DriverAccountStatus.pending, isOnline: false, rating: 5, totalTrips: 0);
    }
    final j = await _api.postJson('/drivers/register');
    final tokens = AuthTokens.fromJson(j);
    await _api.tokens.save(access: tokens.accessToken, refresh: tokens.refreshToken);
    return DriverAccount.fromJson(Map<String, dynamic>.from(j['driver'] as Map));
  }

  /// POST /auth/logout — revokes the refresh token server-side, then clears local tokens.
  Future<void> logout() async {
    if (!ApiConfig.useMock) {
      try {
        await _api.postJson('/auth/logout');
      } catch (_) {
        // Best-effort — clear tokens regardless.
      }
    }
    await _api.tokens.clear();
  }

  /// Role claim from the JWT payload (unsigned read — the server remains the authority).
  static String _roleFromToken(String jwt) {
    try {
      final parts = jwt.split('.');
      final payload = String.fromCharCodes(base64Url.decode(base64Url.normalize(parts[1])));
      final m = RegExp(r'"role"\s*:\s*"([a-z_]+)"').firstMatch(payload);
      return m?.group(1) ?? 'rider';
    } catch (_) {
      return 'rider';
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);
