import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

ApiException apiExceptionFromDio(DioException e) {
  final status = e.response?.statusCode;
  final data = e.response?.data;

  if (data is Map) {
    final msg = data['message'];
    if (msg is String && msg.trim().isNotEmpty) {
      return ApiException(msg.trim(), statusCode: status);
    }
  }

  final fallback = e.message ?? 'Erreur réseau';
  return ApiException(fallback, statusCode: status);
}
