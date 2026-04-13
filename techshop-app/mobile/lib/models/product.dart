import 'category.dart';
import 'review.dart';

class ProductCategorySummary {
  ProductCategorySummary({
    required this.id,
    required this.name,
    required this.slug,
    required this.icon,
  });

  final String id;
  final String name;
  final String slug;
  final String icon;

  factory ProductCategorySummary.fromJson(Map<String, dynamic> json) {
    return ProductCategorySummary(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
    );
  }

  factory ProductCategorySummary.fromCategory(Category c) {
    return ProductCategorySummary(id: c.id, name: c.name, slug: c.slug, icon: c.icon);
  }
}

double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

class ProductListItem {
  ProductListItem({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.price,
    required this.comparePrice,
    required this.stock,
    required this.images,
    required this.category,
    required this.avgRating,
    required this.reviewCount,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String slug;
  final String description;
  final double price;
  final double? comparePrice;
  final int stock;
  final List<String> images;
  final ProductCategorySummary category;
  final double avgRating;
  final int reviewCount;
  final DateTime createdAt;

  factory ProductListItem.fromJson(Map<String, dynamic> json) {
    return ProductListItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: _toDouble(json['price']),
      comparePrice: json['comparePrice'] == null ? null : _toDouble(json['comparePrice']),
      stock: (json['stock'] is num)
          ? (json['stock'] as num).round()
          : int.tryParse(json['stock']?.toString() ?? '') ?? 0,
      images: (json['images'] is List)
          ? (json['images'] as List).map((e) => e.toString()).toList(growable: false)
          : const [],
      category: ProductCategorySummary.fromJson((json['category'] as Map?)?.cast<String, dynamic>() ?? const {}),
      avgRating: _toDouble(json['avgRating']),
      reviewCount: (json['reviewCount'] is num)
          ? (json['reviewCount'] as num).round()
          : int.tryParse(json['reviewCount']?.toString() ?? '') ?? 0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class ProductDetail {
  ProductDetail({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.price,
    required this.comparePrice,
    required this.stock,
    required this.images,
    required this.specs,
    required this.category,
    required this.avgRating,
    required this.reviewCount,
    required this.reviews,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String slug;
  final String description;
  final double price;
  final double? comparePrice;
  final int stock;
  final List<String> images;
  final Map<String, dynamic> specs;
  final ProductCategorySummary category;
  final double avgRating;
  final int reviewCount;
  final List<Review> reviews;
  final DateTime createdAt;

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: _toDouble(json['price']),
      comparePrice: json['comparePrice'] == null ? null : _toDouble(json['comparePrice']),
      stock: (json['stock'] is num)
          ? (json['stock'] as num).round()
          : int.tryParse(json['stock']?.toString() ?? '') ?? 0,
      images: (json['images'] is List)
          ? (json['images'] as List).map((e) => e.toString()).toList(growable: false)
          : const [],
      specs: (json['specs'] is Map)
          ? (json['specs'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{},
      category: ProductCategorySummary.fromJson((json['category'] as Map?)?.cast<String, dynamic>() ?? const {}),
      avgRating: _toDouble(json['avgRating']),
      reviewCount: (json['reviewCount'] is num)
          ? (json['reviewCount'] as num).round()
          : int.tryParse(json['reviewCount']?.toString() ?? '') ?? 0,
      reviews: (json['reviews'] is List)
          ? (json['reviews'] as List)
              .whereType<Map>()
              .map((m) => Review.fromJson(m.cast<String, dynamic>()))
              .toList(growable: false)
          : const [],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
