import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DemoOrdersStorage {
  static const String _key = 'techshop.demoOrders';

  Future<List<Map<String, dynamic>>> loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <Map<String, dynamic>>[];

      return decoded.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList(growable: false);
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> saveOrders(List<Map<String, dynamic>> orders) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(orders);
    await prefs.setString(_key, raw);
  }

  Future<void> prependOrder(Map<String, dynamic> order) async {
    final orders = (await loadOrders()).toList(growable: true);
    orders.insert(0, order);
    await saveOrders(orders);
  }

  Future<Map<String, dynamic>?> findById(String orderId) async {
    final orders = await loadOrders();
    for (final o in orders) {
      if (o['id']?.toString() == orderId) return o;
    }
    return null;
  }

  Future<bool> replaceById(String orderId, Map<String, dynamic> replacement) async {
    final orders = (await loadOrders()).toList(growable: true);
    final idx = orders.indexWhere((o) => o['id']?.toString() == orderId);
    if (idx < 0) return false;
    orders[idx] = replacement;
    await saveOrders(orders);
    return true;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
