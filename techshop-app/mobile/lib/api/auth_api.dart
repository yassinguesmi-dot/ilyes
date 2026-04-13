import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../models/user.dart';

class AuthTokens {
  AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
    );
  }
}

class AuthResult {
  AuthResult({required this.user, required this.tokens});

  final User user;
  final AuthTokens tokens;

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      user: User.fromJson((json['user'] as Map?)?.cast<String, dynamic>() ?? const {}),
      tokens: AuthTokens.fromJson((json['tokens'] as Map?)?.cast<String, dynamic>() ?? const {}),
    );
  }
}

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<AuthResult> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      final resp = await _client.dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'fullName': fullName,
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        },
        options: Options(extra: const {'skipAuth': true}),
      );

      if (resp.data is! Map) throw ApiException('Réponse invalide');
      return AuthResult.fromJson((resp.data as Map).cast<String, dynamic>());
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  Future<AuthResult> login({required String email, required String password}) async {
    try {
      final resp = await _client.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
        options: Options(extra: const {'skipAuth': true}),
      );

      if (resp.data is! Map) throw ApiException('Réponse invalide');
      return AuthResult.fromJson((resp.data as Map).cast<String, dynamic>());
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  Future<AuthTokens> refreshToken(String refreshToken) async {
    try {
      final resp = await _client.dio.post(
        '/auth/refresh-token',
        data: {'refreshToken': refreshToken},
        options: Options(extra: const {'skipAuth': true}),
      );

      if (resp.data is! Map) throw ApiException('Réponse invalide');
      final map = (resp.data as Map).cast<String, dynamic>();
      final tokens = map['tokens'];
      if (tokens is! Map) throw ApiException('Réponse invalide');
      return AuthTokens.fromJson(tokens.cast<String, dynamic>());
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  Future<void> logout() async {
    try {
      await _client.dio.post('/auth/logout');
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }
}
