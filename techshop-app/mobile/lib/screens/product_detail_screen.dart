import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/products_api.dart';
import '../core/format/money.dart';
import '../models/product.dart';
import '../stores/auth_store.dart';
import '../stores/cart_store.dart';
import '../stores/wishlist_store.dart';
import 'auth_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<ProductDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<ProductDetail> _load() async {
    return context.read<ProductsApi>().getProductDetail(widget.slug);
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _toggleWishlist(String productId) async {
    final auth = context.read<AuthStore>();
    if (!auth.isAuthenticated) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthScreen()));
    }

    if (!mounted) return;
    if (!context.read<AuthStore>().isAuthenticated) return;

    try {
      await context.read<WishlistStore>().toggle(productId);
    } catch (_) {
      if (!mounted) return;
      final msg = context.read<WishlistStore>().error ?? 'Wishlist indisponible.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produit'),
        actions: [
          Consumer<WishlistStore>(
            builder: (context, wishlist, _) {
              return FutureBuilder<ProductDetail>(
                future: _future,
                builder: (context, snapshot) {
                  final p = snapshot.data;
                  final isFav = p != null && wishlist.containsProduct(p.id);
                  return IconButton(
                    onPressed: p == null ? null : () => _toggleWishlist(p.id),
                    icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                  );
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<ProductDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Impossible de charger le produit.'),
                const SizedBox(height: 12),
                FilledButton(onPressed: _reload, child: const Text('Réessayer')),
              ],
            );
          }

          final p = snapshot.data!;
          final imageUrls = p.images;
          final specs = p.specs;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (imageUrls.isNotEmpty)
                SizedBox(
                  height: 280,
                  child: PageView.builder(
                    itemCount: imageUrls.length,
                    itemBuilder: (context, index) {
                      final url = imageUrls[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade900,
                            child: Padding(
                              padding: const EdgeInsets.all(48),
                              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                  ),
                ),
              const SizedBox(height: 16),
              Text(p.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(formatTnd(p.price), style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(width: 10),
                  if (p.comparePrice != null)
                    Text(
                      formatTnd(p.comparePrice!),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                    ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: p.stock > 0 ? Colors.green.withAlpha(46) : Colors.red.withAlpha(46),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: p.stock > 0 ? Colors.green.withAlpha(102) : Colors.red.withAlpha(102),
                      ),
                    ),
                    child: Text(p.stock > 0 ? 'En stock' : 'Rupture'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(p.description, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: p.stock <= 0
                    ? null
                    : () async {
                        await context.read<CartStore>().addProductDetail(p, quantity: 1);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ajouté au panier')),
                        );
                      },
                child: const Text('Ajouter au panier'),
              ),
              const SizedBox(height: 22),
              if (specs.isNotEmpty) ...[
                Text('Caractéristiques', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                ...specs.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            e.key,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 6,
                          child: Text(e.value.toString()),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (p.reviews.isNotEmpty) ...[
                Text('Avis', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                ...p.reviews.take(3).map(
                      (r) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(r.user.fullName, style: Theme.of(context).textTheme.titleSmall),
                                  const Spacer(),
                                  Text('${r.rating.toStringAsFixed(1)}/5'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(r.comment ?? ''),
                            ],
                          ),
                        ),
                      ),
                    ),
              ],
            ],
          );
        },
      ),
    );
  }
}
