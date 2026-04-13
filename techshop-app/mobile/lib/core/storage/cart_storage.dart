import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/cart_item.dart';

class CartStorage {
  static const _key = 'techshop.cart';

  Future<List<CartItem>> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((m) => CartItem.fromJson(m.cast<String, dynamic>()))
          .toList(growable: false);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveItems(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((i) => i.toJson()).toList(growable: false));
    await prefs.setString(_key, raw);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
