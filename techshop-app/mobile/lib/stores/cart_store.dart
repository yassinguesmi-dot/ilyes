import 'package:flutter/foundation.dart';

import '../core/storage/cart_storage.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartStore extends ChangeNotifier {
  CartStore({required CartStorage storage}) : _storage = storage;

  final CartStorage _storage;

  final List<CartItem> _items = [];
  bool _bootstrapped = false;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isBootstrapped => _bootstrapped;

  int get totalQuantity => _items.fold<int>(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.fold<double>(0, (sum, item) => sum + item.price * item.quantity);

  Future<void> bootstrap() async {
    if (_bootstrapped) return;
    final loaded = await _storage.loadItems();
    _items
      ..clear()
      ..addAll(loaded);
    _bootstrapped = true;
    notifyListeners();
  }

  Future<void> clear() async {
    _items.clear();
    notifyListeners();
    await _storage.clear();
  }

  Future<void> addProductDetail(ProductDetail product, {int quantity = 1}) async {
    final image = product.images.isNotEmpty ? product.images.first : null;
    await addItem(
      productId: product.id,
      slug: product.slug,
      name: product.name,
      price: product.price,
      imageUrl: image,
      stock: product.stock,
      quantity: quantity,
    );
  }

  Future<void> addItem({
    required String productId,
    required String slug,
    required String name,
    required double price,
    required String? imageUrl,
    required int stock,
    int quantity = 1,
  }) async {
    if (quantity <= 0) return;

    final idx = _items.indexWhere((i) => i.productId == productId);
    if (idx >= 0) {
      final existing = _items[idx];
      final newQty = (existing.quantity + quantity).clamp(1, stock);
      _items[idx] = existing.copyWith(
        name: name,
        price: price,
        imageUrl: imageUrl,
        stock: stock,
        quantity: newQty,
        slug: slug,
      );
    } else {
      final q = quantity.clamp(1, stock);
      _items.add(
        CartItem(
          productId: productId,
          name: name,
          price: price,
          imageUrl: imageUrl,
          stock: stock,
          quantity: q,
          slug: slug,
        ),
      );
    }

    notifyListeners();
    await _storage.saveItems(_items);
  }

  Future<void> setQuantity(String productId, int quantity) async {
    final idx = _items.indexWhere((i) => i.productId == productId);
    if (idx < 0) return;

    if (quantity <= 0) {
      _items.removeAt(idx);
    } else {
      final existing = _items[idx];
      final q = quantity.clamp(1, existing.stock);
      _items[idx] = existing.copyWith(quantity: q);
    }

    notifyListeners();
    await _storage.saveItems(_items);
  }

  Future<void> remove(String productId) async {
    _items.removeWhere((i) => i.productId == productId);
    notifyListeners();
    await _storage.saveItems(_items);
  }
}
