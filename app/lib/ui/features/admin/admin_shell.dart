import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/tez_repository.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../kassa/kassa_view.dart';
import '../kassa/kassa_view_model.dart';
import 'catalogs_view.dart';
import 'catalogs_view_model.dart';
import 'product_form_view.dart';
import 'products_view.dart';
import 'products_view_model.dart';
import 'reports_view.dart';
import 'reports_view_model.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;
  late final ProductsViewModel _products;
  late final CatalogsViewModel _catalogs;
  late final ReportsViewModel _reports;
  late final ReportsViewModel _today;
  late final KassaViewModel _kassa;

  @override
  void initState() {
    super.initState();
    final repo = context.read<TezRepository>();
    _products = ProductsViewModel(repo)..load();
    _catalogs = CatalogsViewModel(repo)..load();
    _reports = ReportsViewModel(repo)..load();
    _today = ReportsViewModel(repo)..load();
    _kassa = KassaViewModel(repo)..start();
  }

  @override
  void dispose() {
    _products.dispose();
    _catalogs.dispose();
    _reports.dispose();
    _today.dispose();
    _kassa.dispose();
    super.dispose();
  }

  void _select(int index) {
    setState(() => _index = index);
    if (index == 0) _today.load();
    if (index == 1) _products.load();
    if (index == 2) _catalogs.load();
    if (index == 3) _reports.load();
    if (index == 4) _kassa.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _kassa,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final pages = [
              _TodayPage(model: _today, onOpenKassa: () => _select(4), onAddProduct: _addProduct),
              ProductsView(model: _products),
              CatalogsView(model: _catalogs),
              ReportsView(model: _reports, embedded: true),
              KassaView(model: _kassa, embedded: true),
            ];
            return Scaffold(
              appBar: AppBar(
                title: const BrandLockup(compact: true),
                actions: [
                  IconButton(
                    tooltip: 'Chiqish',
                    onPressed: () async {
                      await context.read<TezRepository>().logout(admin: true);
                      if (context.mounted) context.go('/');
                    },
                    icon: const Icon(Icons.logout),
                  ),
                ],
              ),
              body: wide
                  ? Row(
                      children: [
                        NavigationRail(
                          selectedIndex: _index,
                          onDestinationSelected: _select,
                          labelType: NavigationRailLabelType.all,
                          backgroundColor: TezColors.white,
                          selectedIconTheme: const IconThemeData(color: TezColors.ink),
                          indicatorColor: TezColors.yellow,
                          destinations: _rail(),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(child: IndexedStack(index: _index, children: pages)),
                      ],
                    )
                  : IndexedStack(index: _index, children: pages),
              bottomNavigationBar: wide
                  ? null
                  : NavigationBar(
                      selectedIndex: _index,
                      onDestinationSelected: _select,
                      destinations: [
                        const NavigationDestination(icon: Icon(Icons.today_outlined), label: 'Bugun'),
                        const NavigationDestination(icon: Icon(Icons.restaurant_outlined), label: 'Taom'),
                        const NavigationDestination(icon: Icon(Icons.folder_outlined), label: 'Katalog'),
                        const NavigationDestination(icon: Icon(Icons.pie_chart_outline), label: 'Hisobot'),
                        NavigationDestination(icon: _kassaIcon(false), selectedIcon: _kassaIcon(true), label: 'Kassa'),
                      ],
                    ),
            );
          },
        );
      },
    );
  }

  List<NavigationRailDestination> _rail() {
    return [
      const NavigationRailDestination(icon: Icon(Icons.today_outlined), label: Text('Bugun')),
      const NavigationRailDestination(icon: Icon(Icons.restaurant_outlined), label: Text('Taom')),
      const NavigationRailDestination(icon: Icon(Icons.folder_outlined), label: Text('Katalog')),
      const NavigationRailDestination(icon: Icon(Icons.pie_chart_outline), label: Text('Hisobot')),
      NavigationRailDestination(icon: _kassaIcon(false), label: const Text('Kassa')),
    ];
  }

  Widget _kassaIcon(bool selected) {
    return Badge(
      isLabelVisible: _kassa.pending > 0,
      backgroundColor: TezColors.pink,
      label: Text('${_kassa.pending}'),
      child: Icon(selected ? Icons.point_of_sale : Icons.point_of_sale_outlined),
    );
  }

  Future<void> _addProduct() async {
    final saved = await openProductForm(context);
    if (saved == true) _products.load();
  }
}

class _TodayPage extends StatelessWidget {
  const _TodayPage({required this.model, required this.onOpenKassa, required this.onAddProduct});

  final ReportsViewModel model;
  final VoidCallback onOpenKassa;
  final VoidCallback onAddProduct;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final report = model.report;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text('Bugungi savdo', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            const Text(
              'Tushum, xarajat, foyda va foiz shu kundagi bekor qilinmagan buyurtmalar bo\'yicha.',
              style: TextStyle(color: TezColors.muted),
            ),
            const SizedBox(height: 16),
            if (model.loading && report == null)
              const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
            else if (model.error != null)
              ErrorPane(message: model.error!, onRetry: model.load)
            else if (report != null) ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 760;
                  return GridView.count(
                    crossAxisCount: wide ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: wide ? 1.2 : 1.05,
                    children: [
                      MoneyTile(label: 'Tushum', value: som(report.revenue), color: TezColors.yellowDeep),
                      MoneyTile(label: 'Jami xarajat', value: som(report.expense), color: TezColors.pink),
                      MoneyTile(label: 'Jami foyda', value: som(report.profit), color: TezColors.green),
                      MoneyTile(label: 'Jami sof foyda', value: som(report.netProfit), color: TezColors.ink),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Taom ${report.soldQuantity} ta sotildi  ·  Buyurtma ${report.salesCount} ta  ·  Sof foyda foizi ${percentText(report.profitPercent)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(onPressed: onAddProduct, icon: const Icon(Icons.add), label: const Text('Taom qo\'shish')),
                OutlinedButton.icon(onPressed: onOpenKassa, icon: const Icon(Icons.point_of_sale), label: const Text('Kassa')),
              ],
            ),
          ],
        );
      },
    );
  }
}
