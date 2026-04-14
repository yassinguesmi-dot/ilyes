import 'package:dio/dio.dart';

import '../core/demo/demo_orders_storage.dart';
import '../core/demo/demo_stock_storage.dart';
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
      if (e.response == null) {
        final raw = await DemoOrdersStorage().loadOrders();
        final demo = raw.map(OrderListItem.fromJson).toList(growable: true);
        demo.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return demo;
      }
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
      if (e.response == null) {
        final raw = await DemoOrdersStorage().findById(orderId);
        if (raw == null) throw ApiException('Commande introuvable');
        return OrderDetail.fromJson(raw);
      }
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
      if (e.response == null) {
        final storage = DemoOrdersStorage();
        final existing = await storage.findById(orderId);
        if (existing == null) return;

        final status = existing['status']?.toString();
        if (status == 'CANCELLED') return;

        final detail = OrderDetail.fromJson(existing);
        final overrides = await DemoStockStorage().load();
        for (final item in detail.items) {
          final pid = item.product.id;
          overrides[pid] = (overrides[pid] ?? 0) + item.quantity;
        }
        await DemoStockStorage().save(overrides);

        final updated = Map<String, dynamic>.from(existing);
        updated['status'] = 'CANCELLED';
        updated['updatedAt'] = DateTime.now().toIso8601String();
        await storage.replaceById(orderId, updated);
        return;
      }
      throw apiExceptionFromDio(e);
    }
  }
}
