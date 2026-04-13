import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../models/user.dart';

class SecureStorage {
  static const _accessTokenKey = 'techshop.accessToken';
  static const _refreshTokenKey = 'techshop.refreshToken';
  static const _userKey = 'techshop.user';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<void> saveUser(User user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<User?> getUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return User.fromJson(decoded);
    } catch (_) {
      await _storage.delete(key: _userKey);
      return null;
    }
  }

  Future<void> clearUser() => _storage.delete(key: _userKey);

  Future<void> clearAuthStorage() async {
    await clearTokens();
    await clearUser();
  }
}
