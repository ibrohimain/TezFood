import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/repositories/tez_repository.dart';
import 'features/admin/admin_shell.dart';
import 'features/auth/pin_view.dart';
import 'features/cart/cart_model.dart';
import 'features/cart/cart_view.dart';
import 'features/cart/cart_view_model.dart';
import 'features/home/home_view.dart';
import 'features/kassa/kassa_view.dart';
import 'features/kassa/kassa_view_model.dart';
import 'features/menu/menu_view.dart';
import 'features/menu/menu_view_model.dart';
import 'session.dart';

GoRouter buildRouter(SessionModel session) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: session,
    redirect: (context, state) {
      final path = state.uri.path;
      if (path.startsWith('/admin') && !session.isAdmin) return '/pin/admin';
      if (path.startsWith('/kassa') && !session.isKassa) return '/pin/kassa';
      if (path == '/pin/admin' && session.isAdmin) return '/admin';
      if (path == '/pin/kassa' && session.isKassa) return '/kassa';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeView()),
      GoRoute(path: '/menu', builder: (context, state) => const MenuPage()),
      GoRoute(path: '/cart', builder: (context, state) => const CartPage()),
      GoRoute(path: '/kassa', builder: (context, state) => const KassaPage()),
      GoRoute(path: '/admin', builder: (context, state) => const AdminShell()),
      GoRoute(
        path: '/pin/:role',
        builder: (context, state) => PinView(role: state.pathParameters['role'] ?? 'kassa'),
      ),
    ],
  );
}

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  late final MenuViewModel _model = MenuViewModel(context.read<TezRepository>())..load();

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MenuView(model: _model);
}

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late final CartViewModel _model = CartViewModel(
    context.read<TezRepository>(),
    context.read<CartModel>(),
  );

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CartView(model: _model);
}

class KassaPage extends StatefulWidget {
  const KassaPage({super.key});

  @override
  State<KassaPage> createState() => _KassaPageState();
}

class _KassaPageState extends State<KassaPage> {
  late final KassaViewModel _model = KassaViewModel(context.read<TezRepository>())..start();

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KassaView(model: _model);
}
