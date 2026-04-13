import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../models/category.dart';
import '../models/cursor_page.dart';
import '../models/product.dart';

class ProductsApi {
  ProductsApi(this._client);

  final ApiClient _client;

  Future<List<Category>> getCategories() async {
    try {
      final resp = await _client.dio.get('/categories');
      final data = resp.data;
      if (data is! Map) throw ApiException('Réponse invalide');

      final items = data['items'];
      if (items is! List) return [];

      return items
          .whereType<Map>()
          .map((m) => Category.fromJson(m.cast<String, dynamic>()))
          .toList(growable: false);
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  Future<CursorPage<ProductListItem>> getProducts({
    String? cursor,
    int limit = 20,
    String? category,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
    String sort = 'newest',
  }) async {
    try {
      final resp = await _client.dio.get(
        '/products',
        queryParameters: {
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
          'limit': limit,
          if (category != null && category.isNotEmpty) 'category': category,
          if (minPrice != null) 'minPrice': minPrice,
          if (maxPrice != null) 'maxPrice': maxPrice,
          if (inStock != null) 'inStock': inStock,
          'sort': sort,
        },
      );

      final data = resp.data;
      if (data is! Map) throw ApiException('Réponse invalide');

      return CursorPage.fromJson(data.cast<String, dynamic>(), ProductListItem.fromJson);
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  Future<List<ProductListItem>> getFeaturedProducts() async {
    try {
      final resp = await _client.dio.get('/products/featured');
      final data = resp.data;
      if (data is! Map) throw ApiException('Réponse invalide');

      final items = data['items'];
      if (items is! List) return [];

      return items
          .whereType<Map>()
          .map((m) => ProductListItem.fromJson(m.cast<String, dynamic>()))
          .toList(growable: false);
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  Future<ProductDetail> getProductDetail(String slug) async {
    try {
      final resp = await _client.dio.get('/products/$slug');
      final data = resp.data;
      if (data is! Map) throw ApiException('Réponse invalide');

      final product = data['product'];
      if (product is! Map) throw ApiException('Produit introuvable');

      return ProductDetail.fromJson(product.cast<String, dynamic>());
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  Future<List<ProductListItem>> searchProducts(String q, {int limit = 20}) async {
    try {
      final resp = await _client.dio.get(
        '/products/search',
        queryParameters: {
          'q': q,
          'limit': limit,
        },
      );

      final data = resp.data;
      if (data is! Map) throw ApiException('Réponse invalide');

      final items = data['items'];
      if (items is! List) return [];

      return items
          .whereType<Map>()
          .map((m) => ProductListItem.fromJson(m.cast<String, dynamic>()))
          .toList(growable: false);
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }
}
