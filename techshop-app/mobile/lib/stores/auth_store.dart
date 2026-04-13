import 'package:flutter/foundation.dart';

import '../api/auth_api.dart';
import '../api/user_api.dart';
import '../core/api/api_exception.dart';
import '../core/storage/secure_storage.dart';
import '../models/user.dart';

class AuthStore extends ChangeNotifier {
  AuthStore({
    required SecureStorage secureStorage,
    required AuthApi authApi,
    required UserApi userApi,
  })  : _secureStorage = secureStorage,
        _authApi = authApi,
        _userApi = userApi;

  final SecureStorage _secureStorage;
  final AuthApi _authApi;
  final UserApi _userApi;

  User? _user;
  bool _isLoading = false;
  bool _bootstrapped = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isBootstrapped => _bootstrapped;
  bool get isAuthenticated => _user != null;
  String? get error => _error;

  Future<void> bootstrap() async {
    if (_bootstrapped) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final storedUser = await _secureStorage.getUser();
      final accessToken = await _secureStorage.getAccessToken();

      if (storedUser != null) {
        _user = storedUser;
        notifyListeners();
      }

      if (accessToken == null || accessToken.isEmpty) {
        _user = null;
        _bootstrapped = true;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final me = await _userApi.getMe();
      _user = me;
      await _secureStorage.saveUser(me);
    } catch (_) {
      await _secureStorage.clearAuthStorage();
      _user = null;
    } finally {
      _bootstrapped = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authApi.login(email: email, password: password);
      await _secureStorage.saveTokens(
        accessToken: result.tokens.accessToken,
        refreshToken: result.tokens.refreshToken,
      );
      await _secureStorage.saveUser(result.user);
      _user = result.user;
    } on ApiException catch (e) {
      _error = e.message;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authApi.register(email: email, password: password, fullName: fullName, phone: phone);
      await _secureStorage.saveTokens(
        accessToken: result.tokens.accessToken,
        refreshToken: result.tokens.refreshToken,
      );
      await _secureStorage.saveUser(result.user);
      _user = result.user;
    } on ApiException catch (e) {
      _error = e.message;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshMe() async {
    try {
      final me = await _userApi.getMe();
      _user = me;
      await _secureStorage.saveUser(me);
      notifyListeners();
    } catch (_) {
      await _secureStorage.clearAuthStorage();
      _user = null;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authApi.logout();
    } catch (_) {
    } finally {
      await _secureStorage.clearAuthStorage();
      _user = null;
      _isLoading = false;
      notifyListeners();
    }
  }
}
