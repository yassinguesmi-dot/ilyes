import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../stores/auth_store.dart';
import '../stores/cart_store.dart';
import '../stores/wishlist_store.dart';
import 'main_shell.dart';

class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  late final Future<void> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrap();
  }

  Future<void> _bootstrap() async {
    final authStore = context.read<AuthStore>();
    final cartStore = context.read<CartStore>();
    final wishlistStore = context.read<WishlistStore>();

    await authStore.bootstrap();
    await cartStore.bootstrap();

    if (!mounted) return;
    if (authStore.isAuthenticated) {
      await wishlistStore.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return const MainShell();
      },
    );
  }
}
