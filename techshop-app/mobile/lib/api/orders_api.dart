import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../models/order.dart';

class CreateOrderResponse {
  CreateOrderResponse({required this.id, required this.status});

  final String id;
  final String status;

  factory CreateOrderResponse.fromJson(Map<String, dynamic> json) {
    return CreateOrderResponse(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
    );
  }
}

class OrdersApi {
  OrdersApi(this._client);

  final ApiClient _client;

  Future<List<OrderListItem>> myOrders() async {
    try {
      final resp = await _client.dio.get('/orders');
      final data = resp.data;
      if (data is! Map) throw ApiException('Réponse invalide');

      final items = data['items'];
      if (items is! List) return [];

      return items
          .whereType<Map>()
          .map((m) => OrderListItem.fromJson(m.cast<String, dynamic>()))
          .toList(growable: false);
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  Future<OrderDetail> myOrderDetail(String orderId) async {
    try {
      final resp = await _client.dio.get('/orders/$orderId');
      final data = resp.data;
      if (data is! Map) throw ApiException('Réponse invalide');

      final order = data['order'];
      if (order is! Map) throw ApiException('Commande introuvable');

      return OrderDetail.fromJson(order.cast<String, dynamic>());
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  Future<CreateOrderResponse> createOrder({
    required List<Map<String, dynamic>> items,
    required String addressId,
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      final resp = await _client.dio.post(
        '/orders',
        data: {
          'items': items,
          'addressId': addressId,
          'paymentMethod': paymentMethod,
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        },
      );

      final data = resp.data;
      if (data is! Map) throw ApiException('Réponse invalide');
      return CreateOrderResponse.fromJson(data.cast<String, dynamic>());
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await _client.dio.put('/orders/$orderId/cancel');
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }
}
