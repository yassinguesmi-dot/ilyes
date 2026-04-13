import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';

class StripeSession {
  StripeSession({required this.url, required this.sessionId});

  final String url;
  final String sessionId;

  factory StripeSession.fromJson(Map<String, dynamic> json) {
    return StripeSession(
      url: json['url']?.toString() ?? '',
      sessionId: json['sessionId']?.toString() ?? '',
    );
  }
}

class PaymentApi {
  PaymentApi(this._client);

  final ApiClient _client;

  Future<StripeSession> createStripeCheckoutSession(String orderId) async {
    try {
      final resp = await _client.dio.post('/payment/create-session', data: {'orderId': orderId});
      final data = resp.data;
      if (data is! Map) throw ApiException('Réponse invalide');
      return StripeSession.fromJson(data.cast<String, dynamic>());
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }
}
