import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DemoStockStorage {
  static const String _key = 'techshop.demoStock';

  Future<Map<String, int>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <String, int>{};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, int>{};

      final out = <String, int>{};
      for (final entry in decoded.entries) {
        final key = entry.key;
        final value = entry.value;

        if (key is! String || key.trim().isEmpty) continue;

        if (value is num) {
          out[key] = value.round();
          continue;
        }

        if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null) out[key] = parsed;
        }
      }

      return out;
    } catch (_) {
      return <String, int>{};
    }
  }

  Future<void> save(Map<String, int> overrides) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(overrides);
    await prefs.setString(_key, raw);
  }

  Future<void> setStock(String productId, int stock) async {
    final overrides = await load();
    overrides[productId] = stock < 0 ? 0 : stock;
    await save(overrides);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
