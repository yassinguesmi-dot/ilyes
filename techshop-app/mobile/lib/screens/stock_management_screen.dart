import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/products_api.dart';
import '../core/api/api_exception.dart';
import '../core/demo/demo_stock_storage.dart';
import '../core/format/money.dart';
import '../models/product.dart';

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  final DemoStockStorage _demoStockStorage = DemoStockStorage();

  late Future<List<ProductListItem>> _future;
  List<ProductListItem> _items = const [];
  final Set<String> _updating = <String>{};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ProductListItem>> _load() async {
    final page = await context.read<ProductsApi>().getProducts(limit: 50);
    _items = page.items;
    return _items;
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  ProductListItem _withStock(ProductListItem p, int stock) {
    return ProductListItem(
      id: p.id,
      name: p.name,
      slug: p.slug,
      description: p.description,
      price: p.price,
      comparePrice: p.comparePrice,
      stock: stock,
      images: p.images,
      category: p.category,
      avgRating: p.avgRating,
      reviewCount: p.reviewCount,
      createdAt: p.createdAt,
    );
  }

  Future<void> _setStock(ProductListItem p, int newStock) async {
    final stock = newStock < 0 ? 0 : newStock;

    if (_updating.contains(p.id)) return;

    final oldStock = p.stock;

    setState(() {
      _updating.add(p.id);
      _items = _items.map((it) => it.id == p.id ? _withStock(it, stock) : it).toList(growable: false);
    });

    try {
      await context.read<ProductsApi>().updateProductStock(p.id, stock);
    } on ApiException catch (e) {
      if (e.statusCode == null) {
        await _demoStockStorage.setStock(p.id, stock);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        setState(() {
          _items = _items.map((it) => it.id == p.id ? _withStock(it, oldStock) : it).toList(growable: false);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _updating.remove(p.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion stock'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<ProductListItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Impossible de charger les produits.'),
                const SizedBox(height: 12),
                FilledButton(onPressed: _reload, child: const Text('Réessayer')),
              ],
            );
          }

          final items = snapshot.data ?? _items;
          if (items.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: const [Text('Aucun produit.')],
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final p = items[index];
                final imageUrl = p.images.isNotEmpty ? p.images.first : null;
                final updating = _updating.contains(p.id);

                return ListTile(
                  tileColor: Colors.grey.shade900,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: imageUrl == null
                          ? ColoredBox(
                              color: Colors.black,
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                              ),
                            )
                          : Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => ColoredBox(
                                color: Colors.black,
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                                ),
                              ),
                            ),
                    ),
                  ),
                  title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${formatTnd(p.price)} • Stock: ${p.stock}'),
                  trailing: SizedBox(
                    width: 132,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: updating || p.stock <= 0 ? null : () => _setStock(p, p.stock - 1),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        SizedBox(
                          width: 28,
                          child: Text(
                            p.stock.toString(),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          onPressed: updating ? null : () => _setStock(p, p.stock + 1),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
