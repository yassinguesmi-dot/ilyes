import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/auth_api.dart';
import '../api/orders_api.dart';
import '../api/payment_api.dart';
import '../api/products_api.dart';
import '../api/user_api.dart';
import '../core/api/api_client.dart';
import '../core/storage/cart_storage.dart';
import '../core/storage/secure_storage.dart';
import '../stores/auth_store.dart';
import '../stores/cart_store.dart';
import '../stores/wishlist_store.dart';
import 'root_gate.dart';

class TechShopApp extends StatelessWidget {
  const TechShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    final secureStorage = SecureStorage();
    final apiClient = ApiClient(secureStorage);

    return MultiProvider(
      providers: [
        Provider<SecureStorage>.value(value: secureStorage),
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthApi>(create: (_) => AuthApi(apiClient)),
        Provider<ProductsApi>(create: (_) => ProductsApi(apiClient)),
        Provider<UserApi>(create: (_) => UserApi(apiClient)),
        Provider<OrdersApi>(create: (_) => OrdersApi(apiClient)),
        Provider<PaymentApi>(create: (_) => PaymentApi(apiClient)),
        Provider<CartStorage>(create: (_) => CartStorage()),
        ChangeNotifierProvider<AuthStore>(
          create: (ctx) => AuthStore(
            secureStorage: ctx.read<SecureStorage>(),
            authApi: ctx.read<AuthApi>(),
            userApi: ctx.read<UserApi>(),
          ),
        ),
        ChangeNotifierProvider<CartStore>(
          create: (ctx) => CartStore(storage: ctx.read<CartStorage>()),
        ),
        ChangeNotifierProvider<WishlistStore>(
          create: (ctx) => WishlistStore(userApi: ctx.read<UserApi>()),
        ),
      ],
      child: MaterialApp(
        title: 'TechShop',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.grey,
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            surfaceTintColor: Colors.transparent,
          ),
          cardTheme: CardThemeData(
            color: Colors.grey.shade900,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey.shade900,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        home: const RootGate(),
      ),
    );
  }
}
