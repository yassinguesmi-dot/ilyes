import 'package:dio/dio.dart';

import '../core/demo/demo_catalog.dart';
import '../core/demo/demo_stock_storage.dart';
import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../models/category.dart';
import '../models/cursor_page.dart';
import '../models/product.dart';

ProductListItem _withStock(ProductListItem p, int stock) {
  return ProductListItem(
    id: p.id,
    name: p.name,
    slug: p.slug,
    description: p.description,
    price: p.price,
    comparePrice: p.comparePrice,
    stock: stock,
    images: p.images,
    category: p.category,
    avgRating: p.avgRating,
    reviewCount: p.reviewCount,
    createdAt: p.createdAt,
  );
}

ProductDetail _withStockDetail(ProductDetail p, int stock) {
  return ProductDetail(
    id: p.id,
    name: p.name,
    slug: p.slug,
    description: p.description,
    price: p.price,
    comparePrice: p.comparePrice,
    stock: stock,
    images: p.images,
    specs: p.specs,
    category: p.category,
    avgRating: p.avgRating,
    reviewCount: p.reviewCount,
    reviews: p.reviews,
    createdAt: p.createdAt,
  );
}

Future<List<ProductListItem>> _applyDemoStockToListItems(List<ProductListItem> items) async {
  final overrides = await DemoStockStorage().load();
  if (overrides.isEmpty) return items;

  return items
      .map(
        (p) {
          final stock = overrides[p.id];
          if (stock == null) return p;
          return _withStock(p, stock);
        },
      )
      .toList(growable: false);
}

Future<ProductDetail> _applyDemoStockToDetail(ProductDetail p) async {
  final overrides = await DemoStockStorage().load();
  final stock = overrides[p.id];
  if (stock == null) return p;
  return _withStockDetail(p, stock);
}

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
      if (e.response == null) return DemoCatalog.categories;
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
      if (e.response == null) {
        final items = await _applyDemoStockToListItems(DemoCatalog.featured());
        return CursorPage(items: items, nextCursor: null);
      }
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
      if (e.response == null) {
        return _applyDemoStockToListItems(DemoCatalog.featured());
      }
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
      if (e.response == null) {
        final demo = DemoCatalog.detail(slug);
        if (demo != null) return _applyDemoStockToDetail(demo);
        throw ApiException('Produit introuvable');
      }
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
      if (e.response == null) {
        return _applyDemoStockToListItems(DemoCatalog.search(q, limit: limit));
      }
      throw apiExceptionFromDio(e);
    }
  }

  Future<void> updateProductStock(String productId, int stock) async {
    try {
      await _client.dio.put('/products/$productId', data: {'stock': stock});
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }
}
