import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/orders_api.dart';
import '../core/format/money.dart';
import '../models/order.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Future<OrderDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<OrderDetail> _load() async {
    return context.read<OrdersApi>().myOrderDetail(widget.orderId);
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  bool _canCancel(String status) {
    return status != 'CANCELLED' && status != 'SHIPPED' && status != 'DELIVERED';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail commande')),
      body: FutureBuilder<OrderDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Impossible de charger la commande.'),
                const SizedBox(height: 12),
                FilledButton(onPressed: _reload, child: const Text('Réessayer')),
              ],
            );
          }

          final o = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Commande ${o.id}', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Statut: ${o.status}'),
                      Text('Paiement: ${o.paymentMethod}'),
                      const SizedBox(height: 10),
                      Text('Total: ${formatTnd(o.totalAmount)}', style: Theme.of(context).textTheme.titleLarge),
                      if (o.paymentRef != null) ...[
                        const SizedBox(height: 6),
                        Text('Réf: ${o.paymentRef}'),
                      ],
                      if (o.notes != null && o.notes!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('Notes: ${o.notes}'),
                      ],
                      const SizedBox(height: 12),
                      if (_canCancel(o.status))
                        FilledButton.tonal(
                          onPressed: () async {
                            await context.read<OrdersApi>().cancelOrder(o.id);
                            if (!context.mounted) return;
                            await _reload();
                          },
                          child: const Text('Annuler la commande'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Adresse', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      Text(o.address.label),
                      Text(o.address.street),
                      Text('${o.address.postalCode} ${o.address.city}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Articles', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              ...o.items.map(
                (i) {
                  final imageUrl = i.product.images.isNotEmpty ? i.product.images.first : null;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
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
                      title: Text(i.product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${i.quantity} × ${formatTnd(i.unitPrice)}'),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
