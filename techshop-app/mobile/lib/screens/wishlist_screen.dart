import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format/money.dart';
import '../stores/wishlist_store.dart';
import 'product_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  late Future<void> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<WishlistStore>().refresh();
  }

  Future<void> _reload() async {
    setState(() {
      _future = context.read<WishlistStore>().refresh();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: FutureBuilder<void>(
        future: _future,
        builder: (context, snapshot) {
          return Consumer<WishlistStore>(
            builder: (context, wishlist, _) {
              if (snapshot.connectionState != ConnectionState.done && wishlist.items.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (wishlist.items.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text('Aucun produit en wishlist.'),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _reload, child: const Text('Rafraîchir')),
                  ],
                );
              }

              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final item = wishlist.items[index];
                    final p = item.product;
                    final imageUrl = p.images.isNotEmpty ? p.images.first : null;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      title: Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(formatTnd(p.price)),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(slug: p.slug)));
                      },
                      trailing: IconButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await wishlist.toggle(p.id);
                          } catch (_) {
                            final msg = wishlist.error ?? 'Wishlist indisponible.';
                            messenger.showSnackBar(SnackBar(content: Text(msg)));
                          }
                        },
                        icon: const Icon(Icons.favorite),
                        tooltip: 'Retirer',
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: wishlist.items.length,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
