import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/orders_api.dart';
import '../api/payment_api.dart';
import '../api/user_api.dart';
import '../core/api/api_exception.dart';
import '../core/demo/demo_orders_storage.dart';
import '../core/demo/demo_stock_storage.dart';
import '../core/format/money.dart';
import '../models/address.dart';
import '../stores/auth_store.dart';
import '../stores/cart_store.dart';
import 'auth_screen.dart';
import 'order_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late Future<List<Address>> _addressesFuture;
  String? _selectedAddressId;
  String _paymentMethod = 'CASH_ON_DELIVERY';
  bool _placing = false;

  final _createAddressKey = GlobalKey<FormState>();
  final _label = TextEditingController();
  final _street = TextEditingController();
  final _city = TextEditingController();
  final _postalCode = TextEditingController();
  bool _makeDefault = true;

  @override
  void initState() {
    super.initState();
    _addressesFuture = _loadAddresses();
  }

  @override
  void dispose() {
    _label.dispose();
    _street.dispose();
    _city.dispose();
    _postalCode.dispose();
    super.dispose();
  }

  Future<List<Address>> _loadAddresses() async {
    final auth = context.read<AuthStore>();
    if (!auth.isAuthenticated) return [];

    final api = context.read<UserApi>();
    try {
      final items = await api.getAddresses();
      if (_selectedAddressId == null && items.isNotEmpty) {
        _selectedAddressId = items.first.id;
      }
      return items;
    } catch (_) {
      return [];
    }
  }

  Future<void> _reloadAddresses() async {
    setState(() {
      _addressesFuture = _loadAddresses();
    });
    await _addressesFuture;
  }

  Future<String?> _ensureAddressId(List<Address> existing) async {
    if (_selectedAddressId != null) return _selectedAddressId;

    if (_label.text.trim().isEmpty && existing.isNotEmpty) {
      _selectedAddressId = existing.first.id;
      return _selectedAddressId;
    }

    final ok = _createAddressKey.currentState?.validate() ?? false;
    if (!ok) return null;

    try {
      final createdId = await context.read<UserApi>().createAddress(
            Address(
              id: '',
              label: _label.text.trim(),
              street: _street.text.trim(),
              city: _city.text.trim(),
              postalCode: _postalCode.text.trim(),
              isDefault: _makeDefault,
            ),
          );

      _selectedAddressId = createdId;
      return createdId;
    } on ApiException catch (e) {
      if (e.statusCode != null) rethrow;
      final localId = 'local-${DateTime.now().millisecondsSinceEpoch}';
      _selectedAddressId = localId;
      return localId;
    } catch (_) {
      final localId = 'local-${DateTime.now().millisecondsSinceEpoch}';
      _selectedAddressId = localId;
      return localId;
    }
  }

  Address _resolveAddress(List<Address> existing, String addressId) {
    final found = existing.where((a) => a.id == addressId).toList(growable: false);
    if (found.isNotEmpty) return found.first;

    return Address(
      id: addressId,
      label: _label.text.trim().isEmpty ? 'Adresse' : _label.text.trim(),
      street: _street.text.trim(),
      city: _city.text.trim(),
      postalCode: _postalCode.text.trim(),
      isDefault: false,
    );
  }

  Future<CreateOrderResponse> _createDemoOrder({
    required CartStore cart,
    required Address address,
    required String paymentMethod,
  }) async {
    final now = DateTime.now();
    final id = 'DEMO-${now.millisecondsSinceEpoch}';
    final status = paymentMethod == 'CARD' ? 'PENDING' : 'CONFIRMED';

    final total = cart.items.fold<double>(0, (sum, i) => sum + i.price * i.quantity);

    final items = <Map<String, dynamic>>[];
    for (var idx = 0; idx < cart.items.length; idx++) {
      final i = cart.items[idx];
      items.add({
        'id': 'demo-item-$idx',
        'quantity': i.quantity,
        'unitPrice': i.price,
        'product': {
          'id': i.productId,
          'name': i.name,
          'slug': i.slug,
          'images': i.imageUrl == null ? const <String>[] : <String>[i.imageUrl!],
        },
      });
    }

    final orderJson = <String, dynamic>{
      'id': id,
      'status': status,
      'totalAmount': total,
      'paymentMethod': paymentMethod,
      'paymentRef': null,
      'notes': null,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'address': {
        'id': address.id,
        'label': address.label,
        'street': address.street,
        'city': address.city,
        'postalCode': address.postalCode,
      },
      'items': items,
    };

    await DemoOrdersStorage().prependOrder(orderJson);

    final stockStorage = DemoStockStorage();
    final overrides = await stockStorage.load();
    for (final i in cart.items) {
      final current = overrides[i.productId] ?? i.stock;
      final next = current - i.quantity;
      overrides[i.productId] = next < 0 ? 0 : next;
    }
    await stockStorage.save(overrides);

    return CreateOrderResponse(id: id, status: status);
  }

  Future<void> _placeOrder() async {
    final cart = context.read<CartStore>();
    if (cart.items.isEmpty) return;

    final auth = context.read<AuthStore>();
    final ordersApi = context.read<OrdersApi>();
    final paymentApi = context.read<PaymentApi>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!auth.isAuthenticated) {
      await navigator.push(MaterialPageRoute(builder: (_) => const AuthScreen()));
      if (!mounted) return;
      if (!auth.isAuthenticated) return;
      await _reloadAddresses();
    }

    setState(() {
      _placing = true;
    });

    try {
      final addresses = await _addressesFuture;
      final addressId = await _ensureAddressId(addresses);
      if (addressId == null || addressId.isEmpty) {
        if (!mounted) return;
        messenger.showSnackBar(const SnackBar(content: Text('Adresse requise.')));
        return;
      }

      var demoOrder = false;
      late final CreateOrderResponse res;
      try {
        res = await ordersApi.createOrder(
          items: cart.items
              .map((i) => {
                    'productId': i.productId,
                    'quantity': i.quantity,
                  })
              .toList(growable: false),
          addressId: addressId,
          paymentMethod: _paymentMethod,
        );
      } on ApiException catch (e) {
        if (e.statusCode != null) rethrow;
        demoOrder = true;
        final address = _resolveAddress(addresses, addressId);
        res = await _createDemoOrder(cart: cart, address: address, paymentMethod: _paymentMethod);
      }

      await cart.clear();

      String? stripeUrl;
      if (_paymentMethod == 'CARD') {
        if (demoOrder) {
          stripeUrl = null;
          if (mounted) {
            messenger.showSnackBar(const SnackBar(content: Text('Paiement carte indisponible (mode démo).')));
          }
        } else {
          try {
            final session = await paymentApi.createStripeCheckoutSession(res.id);
            final url = session.url.trim();
            final uri = Uri.tryParse(url);

            if (uri != null && uri.hasScheme && url.isNotEmpty) {
              stripeUrl = url;
              try {
                await launchUrl(
                  uri,
                  mode: LaunchMode.platformDefault,
                  webOnlyWindowName: kIsWeb ? '_blank' : null,
                );
              } catch (_) {
                if (mounted) {
                  messenger.showSnackBar(const SnackBar(content: Text("Impossible d'ouvrir le paiement automatiquement.")));
                }
              }
            } else {
              stripeUrl = null;
              if (mounted) {
                messenger.showSnackBar(const SnackBar(content: Text('Paiement carte indisponible.')));
              }
            }
          } on ApiException catch (e) {
            stripeUrl = null;
            if (mounted) {
              messenger.showSnackBar(SnackBar(content: Text(e.message.isEmpty ? 'Paiement carte indisponible.' : e.message)));
            }
          } catch (_) {
            stripeUrl = null;
            if (mounted) {
              messenger.showSnackBar(const SnackBar(content: Text('Paiement carte indisponible.')));
            }
          }
        }
      }

      if (!mounted) return;
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderConfirmationScreen(orderId: res.id, status: res.status, stripeUrl: stripeUrl),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message.isEmpty ? 'Commande impossible.' : e.message)));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Commande impossible.')));
    } finally {
      if (mounted) {
        setState(() {
          _placing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Caisse')),
      body: Consumer<CartStore>(
        builder: (context, cart, _) {
          if (cart.items.isEmpty) {
            return const Center(child: Text('Votre panier est vide.'));
          }

          final isAuth = context.watch<AuthStore>().isAuthenticated;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Résumé', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text('${cart.totalQuantity} articles'),
                          const Spacer(),
                          Text(formatTnd(cart.subtotal), style: Theme.of(context).textTheme.titleLarge),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (!isAuth)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Connexion requise', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 10),
                        const Text('Connectez-vous pour choisir une adresse et passer commande.'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () async {
                            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthScreen()));
                            if (!mounted) return;
                            await _reloadAddresses();
                          },
                          child: const Text('Se connecter'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                FutureBuilder<List<Address>>(
                  future: _addressesFuture,
                  builder: (context, snapshot) {
                    final loading = snapshot.connectionState != ConnectionState.done;
                    final items = snapshot.data ?? const [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Adresse', style: Theme.of(context).textTheme.titleMedium),
                                    IconButton(
                                      onPressed: loading ? null : _reloadAddresses,
                                      icon: const Icon(Icons.refresh),
                                    ),
                                  ],
                                ),
                                if (loading) const LinearProgressIndicator(),
                                const SizedBox(height: 10),
                                if (items.isEmpty)
                                  const Text('Aucune adresse enregistrée. Ajoutez-en une ci-dessous.')
                                else
                                  RadioGroup<String>(
                                    groupValue: _selectedAddressId,
                                    onChanged: (v) {
                                      if (loading || v == null) return;
                                      setState(() => _selectedAddressId = v);
                                    },
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ...items.map(
                                          (a) => RadioListTile<String>(
                                            value: a.id,
                                            enabled: !loading,
                                            title: Text(a.label),
                                            subtitle: Text('${a.street}, ${a.city}'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Form(
                              key: _createAddressKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Nouvelle adresse', style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _label,
                                    decoration: const InputDecoration(labelText: 'Label (ex: Maison)'),
                                    validator: (v) {
                                      final value = (v ?? '').trim();
                                      if (value.isEmpty) return 'Label requis';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _street,
                                    decoration: const InputDecoration(labelText: 'Rue'),
                                    validator: (v) {
                                      final value = (v ?? '').trim();
                                      if (value.isEmpty) return 'Rue requise';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _city,
                                          decoration: const InputDecoration(labelText: 'Ville'),
                                          validator: (v) {
                                            final value = (v ?? '').trim();
                                            if (value.isEmpty) return 'Ville requise';
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _postalCode,
                                          decoration: const InputDecoration(labelText: 'Code postal'),
                                          validator: (v) {
                                            final value = (v ?? '').trim();
                                            if (value.isEmpty) return 'Code postal requis';
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    value: _makeDefault,
                                    onChanged: (v) => setState(() => _makeDefault = v),
                                    title: const Text('Définir comme adresse par défaut'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Paiement', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      RadioGroup<String>(
                        groupValue: _paymentMethod,
                        onChanged: (v) {
                          if (_placing || v == null) return;
                          setState(() => _paymentMethod = v);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RadioListTile<String>(
                              value: 'CASH_ON_DELIVERY',
                              enabled: !_placing,
                              title: const Text('Paiement à la livraison'),
                            ),
                            RadioListTile<String>(
                              value: 'CARD',
                              enabled: !_placing,
                              title: const Text('Carte bancaire'),
                            ),
                            RadioListTile<String>(
                              value: 'BANK_TRANSFER',
                              enabled: !_placing,
                              title: const Text('Virement bancaire'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _placing ? null : _placeOrder,
                child: _placing
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Valider la commande'),
              ),
            ],
          );
        },
      ),
    );
  }
}
