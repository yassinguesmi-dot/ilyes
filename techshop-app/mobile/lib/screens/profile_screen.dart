import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../stores/auth_store.dart';
import '../stores/wishlist_store.dart';
import 'auth_screen.dart';
import 'orders_screen.dart';
import 'wishlist_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _ensureAuth(BuildContext context) async {
    final auth = context.read<AuthStore>();
    if (!auth.isAuthenticated) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthStore>(
      builder: (context, auth, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Profil')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: auth.isAuthenticated
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(auth.user!.fullName, style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 6),
                            Text(auth.user!.email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Connectez-vous', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 6),
                            const Text('Accédez à votre wishlist, commandes et adresses.'),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthScreen())),
                              child: const Text('Se connecter'),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                tileColor: Colors.grey.shade900,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                leading: const Icon(Icons.favorite_border),
                title: const Text('Wishlist'),
                onTap: () async {
                  await _ensureAuth(context);
                  if (!context.mounted) return;
                  if (!context.read<AuthStore>().isAuthenticated) return;
                  await context.read<WishlistStore>().refresh();
                  if (!context.mounted) return;
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WishlistScreen()));
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                tileColor: Colors.grey.shade900,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Mes commandes'),
                onTap: () async {
                  await _ensureAuth(context);
                  if (!context.mounted) return;
                  if (!context.read<AuthStore>().isAuthenticated) return;
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrdersScreen()));
                },
              ),
              const SizedBox(height: 20),
              if (auth.isAuthenticated)
                OutlinedButton(
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                          await auth.logout();
                          if (!context.mounted) return;
                          context.read<WishlistStore>().clearLocal();
                        },
                  child: const Text('Déconnexion'),
                ),
            ],
          ),
        );
      },
    );
  }
}
