import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../models/address.dart';
import '../models/user.dart';
import '../models/wishlist_item.dart';

class UserApi {
  UserApi(this._client);

  final ApiClient _client;

  Future<User> getMe() async {
    try {
      final resp = await _client.dio.get('/users/me');
      final data = resp.data;
      if (data is! Map) throw ApiException('Réponse invalide');

      final user = data['user'];
      if (user is! Map) throw ApiException('Réponse invalide');

      return User.fromJson(user.cast<String, dynamic>());
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  Future<List<WishlistItem>> getWishlist() async {
    try {
      final resp = await _client.dio.get('/users/me/wishlist');
      final data = resp.data;
      if (data is! Map) throw ApiException('Réponse invalide');

      final items = data['items'];
      if (items is! List) return [];

      return items
          .whereType<Map>()
          .map((m) => WishlistItem.fromJson(m.cast<String, dynamic>()))
          .toList(growable: false);
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  Future<void> addToWishlist(String productId) async {
    try {
      await _client.dio.post('/users/me/wishlist/$productId');
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  Future<void> removeFromWishlist(String productId) async {
    try {
      await _client.dio.delete('/users/me/wishlist/$productId');
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  Future<List<Address>> getAddresses() async {
    try {
      final resp = await _client.dio.get('/users/me/addresses');
      final data = resp.data;
      if (data is! Map) throw ApiException('Réponse invalide');

      final items = data['items'];
      if (items is! List) return [];

      return items
          .whereType<Map>()
          .map((m) => Address.fromJson(m.cast<String, dynamic>()))
          .toList(growable: false);
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  Future<String> createAddress(Address address) async {
    try {
      final resp = await _client.dio.post('/users/me/addresses', data: address.toCreateJson());
      final data = resp.data;
      if (data is! Map) throw ApiException('Réponse invalide');
      final id = data['id']?.toString();
      if (id == null || id.isEmpty) throw ApiException('Réponse invalide');
      return id;
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }
}
