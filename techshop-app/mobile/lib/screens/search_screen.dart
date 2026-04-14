import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/products_api.dart';
import '../core/format/money.dart';
import '../models/product.dart';
import '../stores/cart_store.dart';
import 'product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  List<ProductListItem> _results = const [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty) {
      setState(() {
        _results = const [];
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = context.read<ProductsApi>();
      final items = await api.searchProducts(q);
      setState(() {
        _results = items;
      });
    } catch (_) {
      setState(() {
        _error = 'Recherche impossible.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
          decoration: const InputDecoration(
            hintText: 'Rechercher un produit…',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _search,
            icon: const Icon(Icons.arrow_forward),
            tooltip: 'Rechercher',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _results.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: const [
                        Text('Tapez un mot-clé pour chercher des articles.'),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final p = _results[index];
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
                            onPressed: p.stock <= 0
                                ? null
                                : () async {
                                    await context.read<CartStore>().addItem(
                                          productId: p.id,
                                          slug: p.slug,
                                          name: p.name,
                                          price: p.price,
                                          imageUrl: imageUrl,
                                          stock: p.stock,
                                          quantity: 1,
                                        );
                                  },
                            icon: const Icon(Icons.add_shopping_cart_outlined),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: _results.length,
                    ),
    );
  }
}
