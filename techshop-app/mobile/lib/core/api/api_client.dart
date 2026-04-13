import 'package:dio/dio.dart';

import '../env.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  ApiClient(this._storage)
      : dio = Dio(
          BaseOptions(
            baseUrl: apiBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final skipAuth = options.extra['skipAuth'] == true;
          if (!skipAuth) {
            final token = await _storage.getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }

          handler.next(options);
        },
        onError: (error, handler) async {
          final status = error.response?.statusCode;
          final requestOptions = error.requestOptions;

          final skipAuth = requestOptions.extra['skipAuth'] == true;
          final alreadyRetried = requestOptions.extra['retried'] == true;

          if (status != 401 || skipAuth || alreadyRetried) {
            handler.next(error);
            return;
          }

          requestOptions.extra['retried'] = true;

          final newAccessToken = await _refreshAccessToken();
          if (newAccessToken == null || newAccessToken.isEmpty) {
            handler.next(error);
            return;
          }

          requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

          try {
            final response = await dio.fetch(requestOptions);
            handler.resolve(response);
          } catch (e) {
            if (e is DioException) {
              handler.next(e);
            } else {
              handler.next(error);
            }
          }
        },
      ),
    );
  }

  final Dio dio;
  final SecureStorage _storage;

  Future<String?>? _refreshInFlight;

  Future<String?> _refreshAccessToken() {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;

    final future = _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });

    _refreshInFlight = future;
    return future;
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final resp = await dio.post(
        '/auth/refresh-token',
        data: {'refreshToken': refreshToken},
        options: Options(extra: const {'skipAuth': true}),
      );

      final data = resp.data;
      if (data is! Map) return null;

      final tokens = data['tokens'];
      if (tokens is! Map) return null;

      final access = tokens['accessToken'];
      final refresh = tokens['refreshToken'];

      if (access is! String || refresh is! String) return null;

      await _storage.saveTokens(accessToken: access, refreshToken: refresh);
      return access;
    } catch (_) {
      await _storage.clearTokens();
      return null;
    }
  }
}
