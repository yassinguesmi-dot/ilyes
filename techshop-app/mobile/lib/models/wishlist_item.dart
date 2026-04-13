import 'product.dart';

double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

class WishlistProduct {
  WishlistProduct({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    required this.comparePrice,
    required this.stock,
    required this.images,
  });

  final String id;
  final String name;
  final String slug;
  final double price;
  final double? comparePrice;
  final int stock;
  final List<String> images;

  factory WishlistProduct.fromJson(Map<String, dynamic> json) {
    return WishlistProduct(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      price: _toDouble(json['price']),
      comparePrice: json['comparePrice'] == null ? null : _toDouble(json['comparePrice']),
      stock: (json['stock'] is num)
          ? (json['stock'] as num).round()
          : int.tryParse(json['stock']?.toString() ?? '') ?? 0,
      images: (json['images'] is List)
          ? (json['images'] as List).map((e) => e.toString()).toList(growable: false)
          : const [],
    );
  }

  ProductListItem toProductListItem() {
    return ProductListItem(
      id: id,
      name: name,
      slug: slug,
      description: '',
      price: price,
      comparePrice: comparePrice,
      stock: stock,
      images: images,
      category: ProductCategorySummary(id: '', name: '', slug: '', icon: ''),
      avgRating: 0,
      reviewCount: 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class WishlistItem {
  WishlistItem({required this.productId, required this.product});

  final String productId;
  final WishlistProduct product;

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      productId: json['productId']?.toString() ?? '',
      product: WishlistProduct.fromJson((json['product'] as Map?)?.cast<String, dynamic>() ?? const {}),
    );
  }
}
