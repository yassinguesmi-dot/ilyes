class CartItem {
  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.stock,
    required this.quantity,
    required this.slug,
  });

  final String productId;
  final String name;
  final double price;
  final String? imageUrl;
  final int stock;
  final int quantity;
  final String slug;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price']?.toString() ?? '') ?? 0,
        imageUrl: json['imageUrl']?.toString(),
      stock: (json['stock'] is num)
          ? (json['stock'] as num).round()
          : int.tryParse(json['stock']?.toString() ?? '') ?? 0,
      quantity: (json['quantity'] is num)
          ? (json['quantity'] as num).round()
          : int.tryParse(json['quantity']?.toString() ?? '') ?? 1,
      slug: json['slug']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'stock': stock,
      'quantity': quantity,
      'slug': slug,
    };
  }

  CartItem copyWith({
    String? productId,
    String? name,
    double? price,
    String? imageUrl,
    int? stock,
    int? quantity,
    String? slug,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      stock: stock ?? this.stock,
      quantity: quantity ?? this.quantity,
      slug: slug ?? this.slug,
    );
  }
}
