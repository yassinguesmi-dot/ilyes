import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'orders_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key, required this.orderId, required this.status, this.stripeUrl});

  final String orderId;
  final String status;
  final String? stripeUrl;

  @override
  Widget build(BuildContext context) {
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
          if (stripeUrl != null && stripeUrl!.isNotEmpty) ...[
            FilledButton.tonal(
              onPressed: () async {
                final uri = Uri.tryParse(stripeUrl!);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text('Payer maintenant'),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrdersScreen()));
            },
            child: const Text('Voir mes commandes'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Retour à l’accueil'),
          ),
        ],
      ),
    );
  }
}
