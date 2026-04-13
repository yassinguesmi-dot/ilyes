class CursorPage<T> {
  CursorPage({required this.items, required this.nextCursor});

  final List<T> items;
  final String? nextCursor;

  static CursorPage<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> itemJson) fromItemJson,
  ) {
    final rawItems = json['items'];
    final items = (rawItems is List)
        ? rawItems
            .whereType<Map>()
            .map((m) => fromItemJson(m.cast<String, dynamic>()))
            .toList(growable: false)
        : <T>[];

    final cursor = json['nextCursor']?.toString();
    return CursorPage(items: items, nextCursor: (cursor == null || cursor.isEmpty) ? null : cursor);
  }
}
