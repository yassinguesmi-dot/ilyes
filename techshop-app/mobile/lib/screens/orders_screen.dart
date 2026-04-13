import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/orders_api.dart';
import '../core/format/money.dart';
import '../models/order.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<OrderListItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<OrderListItem>> _load() async {
    return context.read<OrdersApi>().myOrders();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes commandes')),
      body: FutureBuilder<List<OrderListItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Impossible de charger les commandes.'),
                const SizedBox(height: 12),
                FilledButton(onPressed: _reload, child: const Text('Réessayer')),
              ],
            );
          }

          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: const [Text('Aucune commande pour le moment.')],
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final o = items[index];
                return ListTile(
                  tileColor: Colors.grey.shade900,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text('Commande ${o.id.substring(0, 8)}…'),
                  subtitle: Text('${o.status} • ${formatTnd(o.totalAmount)}'),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id)));
                  },
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: items.length,
            ),
          );
        },
      ),
    );
  }
}
