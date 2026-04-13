double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

class OrderListItem {
  OrderListItem({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.paymentMethod,
    required this.createdAt,
  });

  final String id;
  final String status;
  final double totalAmount;
  final String paymentMethod;
  final DateTime createdAt;

  factory OrderListItem.fromJson(Map<String, dynamic> json) {
    return OrderListItem(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      totalAmount: _toDouble(json['totalAmount']),
      paymentMethod: json['paymentMethod']?.toString() ?? 'CASH_ON_DELIVERY',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class OrderDetail {
  OrderDetail({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentRef,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.address,
    required this.items,
  });

  final String id;
  final String status;
  final double totalAmount;
  final String paymentMethod;
  final String? paymentRef;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final OrderAddress address;
  final List<OrderItem> items;

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      totalAmount: _toDouble(json['totalAmount']),
      paymentMethod: json['paymentMethod']?.toString() ?? 'CASH_ON_DELIVERY',
      paymentRef: json['paymentRef']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      address: OrderAddress.fromJson((json['address'] as Map?)?.cast<String, dynamic>() ?? const {}),
      items: (json['items'] is List)
          ? (json['items'] as List)
              .whereType<Map>()
              .map((m) => OrderItem.fromJson(m.cast<String, dynamic>()))
              .toList(growable: false)
          : const [],
    );
  }
}

class OrderAddress {
  OrderAddress({
    required this.id,
    required this.label,
    required this.street,
    required this.city,
    required this.postalCode,
  });

  final String id;
  final String label;
  final String street;
  final String city;
  final String postalCode;

  factory OrderAddress.fromJson(Map<String, dynamic> json) {
    return OrderAddress(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      street: json['street']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      postalCode: json['postalCode']?.toString() ?? '',
    );
  }
}

class OrderItemProduct {
  OrderItemProduct({
    required this.id,
    required this.name,
    required this.slug,
    required this.images,
  });

  final String id;
  final String name;
  final String slug;
  final List<String> images;

  factory OrderItemProduct.fromJson(Map<String, dynamic> json) {
    return OrderItemProduct(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      images: (json['images'] is List)
          ? (json['images'] as List).map((e) => e.toString()).toList(growable: false)
          : const [],
    );
  }
}

class OrderItem {
  OrderItem({
    required this.id,
    required this.quantity,
    required this.unitPrice,
    required this.product,
  });

  final String id;
  final int quantity;
  final double unitPrice;
  final OrderItemProduct product;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id']?.toString() ?? '',
      quantity: (json['quantity'] is num)
          ? (json['quantity'] as num).round()
          : int.tryParse(json['quantity']?.toString() ?? '') ?? 1,
      unitPrice: _toDouble(json['unitPrice']),
      product: OrderItemProduct.fromJson((json['product'] as Map?)?.cast<String, dynamic>() ?? const {}),
    );
  }
}
