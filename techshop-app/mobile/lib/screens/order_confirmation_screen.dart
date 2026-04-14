import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/demo/demo_orders_storage.dart';
import 'orders_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key, required this.orderId, required this.status, this.stripeUrl});

  final String orderId;
  final String status;
  final String? stripeUrl;

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmation')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Commande validée', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  Text('ID: $orderId'),
                  Text('Statut: $status'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if ((stripeUrl == null || stripeUrl!.isEmpty) && orderId.startsWith('DEMO-') && status == 'PENDING') ...[
            FilledButton.tonal(
              onPressed: () async {
                final storage = DemoOrdersStorage();
                final existing = await storage.findById(orderId);
                if (existing == null) {
                  if (!context.mounted) return;
                  messenger.showSnackBar(const SnackBar(content: Text('Commande démo introuvable.')));
                  return;
                }

                final updated = Map<String, dynamic>.from(existing);
                updated['status'] = 'CONFIRMED';
                updated['paymentRef'] = 'DEMO-PAID';
                updated['updatedAt'] = DateTime.now().toIso8601String();
                await storage.replaceById(orderId, updated);

                if (!context.mounted) return;
                navigator.pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => OrderConfirmationScreen(orderId: orderId, status: 'CONFIRMED'),
                  ),
                );
              },
              child: const Text('Simuler paiement (démo)'),
            ),
            const SizedBox(height: 12),
          ],
          if (stripeUrl != null && stripeUrl!.isNotEmpty) ...[
            FilledButton.tonal(
              onPressed: () async {
                final uri = Uri.tryParse(stripeUrl!);
                if (uri != null) {
                  try {
                    await launchUrl(
                      uri,
                      mode: LaunchMode.platformDefault,
                      webOnlyWindowName: kIsWeb ? '_blank' : null,
                    );
                  } catch (_) {
                    if (!context.mounted) return;
                    messenger.showSnackBar(const SnackBar(content: Text("Impossible d'ouvrir le lien de paiement.")));
                  }
                }
              },
              child: const Text('Payer maintenant'),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton(
            onPressed: () {
              navigator.push(MaterialPageRoute(builder: (_) => const OrdersScreen()));
            },
            child: const Text('Voir mes commandes'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              navigator.popUntil((route) => route.isFirst);
            },
            child: const Text('Retour à l’accueil'),
          ),
        ],
      ),
    );
  }
}
