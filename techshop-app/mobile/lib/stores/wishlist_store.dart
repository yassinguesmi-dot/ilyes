import 'package:flutter/foundation.dart';

import '../api/user_api.dart';
import '../core/api/api_exception.dart';
import '../models/wishlist_item.dart';

class WishlistStore extends ChangeNotifier {
  WishlistStore({required UserApi userApi}) : _userApi = userApi;

  final UserApi _userApi;

  bool _isLoading = false;
  String? _error;
  List<WishlistItem> _items = const [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<WishlistItem> get items => _items;

  bool containsProduct(String productId) {
    return _items.any((i) => i.productId == productId);
  }

  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _userApi.getWishlist();
    } on ApiException catch (e) {
      _error = e.message;
      _items = const [];
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggle(String productId) async {
    _error = null;
    notifyListeners();

    try {
      if (containsProduct(productId)) {
        await _userApi.removeFromWishlist(productId);
      } else {
        await _userApi.addToWishlist(productId);
      }
      _items = await _userApi.getWishlist();
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }

  void clearLocal() {
    _items = const [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
