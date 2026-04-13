import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/products_api.dart';
import '../core/format/money.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../stores/cart_store.dart';
import '../stores/wishlist_store.dart';
import '../stores/auth_store.dart';
import 'auth_screen.dart';
import 'product_detail_screen.dart';
import 'wishlist_screen.dart';

class _HomeData {
  _HomeData({required this.categories, required this.featured});

  final List<Category> categories;
  final List<ProductListItem> featured;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_HomeData> _load() async {
    final api = context.read<ProductsApi>();
    final categories = await api.getCategories();
    final featured = await api.getFeaturedProducts();
    return _HomeData(categories: categories, featured: featured);
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _openWishlist() async {
    final auth = context.read<AuthStore>();
    if (!auth.isAuthenticated) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthScreen()));
    }

    if (!mounted) return;
    if (!context.read<AuthStore>().isAuthenticated) return;

    await context.read<WishlistStore>().refresh();
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WishlistScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 28, width: 28),
            const SizedBox(width: 10),
            const Text('TechShop'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openWishlist,
            icon: const Icon(Icons.favorite_border),
            tooltip: 'Wishlist',
          ),
          Consumer<CartStore>(
            builder: (context, cart, _) {
              return IconButton(
                onPressed: () {},
                icon: Badge(
                  isLabelVisible: cart.totalQuantity > 0,
                  label: Text(cart.totalQuantity.toString()),
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<_HomeData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Erreur lors du chargement.'),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _reload, child: const Text('Réessayer')),
                ],
              );
            }

            final data = snapshot.data ?? _HomeData(categories: const [], featured: const []);
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (data.categories.isNotEmpty) ...[
                  Text('Catégories', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final c = data.categories[index];
                        return _CategoryChip(name: c.name);
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemCount: data.categories.length,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('À la une', style: Theme.of(context).textTheme.titleMedium),
                    Text('${data.featured.length} articles', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final crossAxisCount = w >= 1100
                        ? 5
                        : w >= 900
                            ? 4
                            : w >= 650
                                ? 3
                                : 2;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: data.featured.length,
                      itemBuilder: (context, index) {
                        final p = data.featured[index];
                        return _ProductCard(
                          product: p,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => ProductDetailScreen(slug: p.slug)),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(name),
      backgroundColor: Colors.grey.shade900,
      side: BorderSide(color: Colors.grey.shade800),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final ProductListItem product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.images.isNotEmpty ? product.images.first : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imageUrl == null
                      ? const Center(child: Icon(Icons.image_not_supported_outlined))
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined)),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                formatTnd(product.price),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () async {
                        final auth = context.read<AuthStore>();
                        if (!auth.isAuthenticated) {
                          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthScreen()));
                          if (!context.mounted) return;
                        }

                        final wishlist = context.read<WishlistStore>();
                        await wishlist.toggle(product.id);
                      },
                      child: const Text('♥'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: product.stock <= 0
                          ? null
                          : () async {
                              await context.read<CartStore>().addItem(
                                    productId: product.id,
                                    slug: product.slug,
                                    name: product.name,
                                    price: product.price,
                                    imageUrl: imageUrl,
                                    stock: product.stock,
                                    quantity: 1,
                                  );
                            },
                      child: const Text('Ajouter'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
