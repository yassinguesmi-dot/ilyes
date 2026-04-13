import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../stores/auth_store.dart';
import '../stores/wishlist_store.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Se connecter'),
            Tab(text: 'Créer un compte'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _LoginTab(),
          _RegisterTab(),
        ],
      ),
    );
  }
}

class _LoginTab extends StatefulWidget {
  const _LoginTab();

  @override
  State<_LoginTab> createState() => _LoginTabState();
}

class _LoginTabState extends State<_LoginTab> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthStore>();
    final wishlist = context.read<WishlistStore>();

    try {
      await auth.login(email: _email.text.trim(), password: _password.text);
      try {
        await wishlist.refresh();
      } catch (_) {}
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      final msg = auth.error ?? 'Connexion impossible.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return 'Email requis';
                if (!value.contains('@')) return 'Email invalide';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: const InputDecoration(labelText: 'Mot de passe'),
              validator: (v) {
                final value = (v ?? '');
                if (value.isEmpty) return 'Mot de passe requis';
                if (value.length < 6) return '6 caractères minimum';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Consumer<AuthStore>(
              builder: (context, auth, _) {
                return FilledButton(
                  onPressed: auth.isLoading ? null : _submit,
                  child: auth.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Se connecter'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterTab extends StatefulWidget {
  const _RegisterTab();

  @override
  State<_RegisterTab> createState() => _RegisterTabState();
}

class _RegisterTabState extends State<_RegisterTab> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthStore>();
    final wishlist = context.read<WishlistStore>();

    try {
      await auth.register(
        email: _email.text.trim(),
        password: _password.text,
        fullName: _fullName.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      );
      try {
        await wishlist.refresh();
      } catch (_) {}
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      final msg = auth.error ?? 'Inscription impossible.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _fullName,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Nom complet'),
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.length < 2) return 'Nom invalide';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Téléphone (optionnel)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return 'Email requis';
                if (!value.contains('@')) return 'Email invalide';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(labelText: 'Mot de passe'),
              validator: (v) {
                final value = (v ?? '');
                if (value.isEmpty) return 'Mot de passe requis';
                if (value.length < 6) return '6 caractères minimum';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Consumer<AuthStore>(
              builder: (context, auth, _) {
                return FilledButton(
                  onPressed: auth.isLoading ? null : _submit,
                  child: auth.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Créer le compte'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
