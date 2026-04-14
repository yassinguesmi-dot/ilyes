import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format/money.dart';
import '../stores/cart_store.dart';
import 'checkout_screen.dart';
import 'product_detail_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panier')),
      body: Consumer<CartStore>(
        builder: (context, cart, _) {
          if (cart.items.isEmpty) {
            return const Center(child: Text('Votre panier est vide.'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      tileColor: Colors.grey.shade900,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: item.imageUrl == null
                              ? ColoredBox(
                                  color: Colors.black,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                                  ),
                                )
                              : Image.network(
                                  item.imageUrl!,
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
                      title: Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(formatTnd(item.price)),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ProductDetailScreen(slug: item.slug)),
                        );
                      },
                      trailing: SizedBox(
                        width: 140,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () => cart.setQuantity(item.productId, item.quantity - 1),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(item.quantity.toString()),
                            IconButton(
                              onPressed: item.quantity >= item.stock
                                  ? null
                                  : () => cart.setQuantity(item.productId, item.quantity + 1),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: cart.items.length,
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Text('Sous-total'),
                          const Spacer(),
                          Text(formatTnd(cart.subtotal), style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CheckoutScreen()));
                        },
                        child: const Text('Passer à la caisse'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
