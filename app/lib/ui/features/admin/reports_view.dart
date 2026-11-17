import 'package:flutter/material.dart';

import '../../../domain/models.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'reports_view_model.dart';

class ReportsView extends StatelessWidget {
  const ReportsView({super.key, required this.model, this.embedded = false});

  final ReportsViewModel model;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        return Scaffold(
          appBar: embedded ? null : AppBar(title: const Text('Hisobot')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in const [
                    ('today', 'Bugun'),
                    ('week', 'Hafta'),
                    ('month', 'Oy'),
                    ('year', 'Yil'),
                    ('season', 'Mavsum'),
                    ('custom', 'Oraliq'),
                  ])
                    ChoiceChip(
                      label: Text(item.$2),
                      selected: model.period == item.$1,
                      selectedColor: TezColors.yellow,
                      onSelected: (_) => item.$1 == 'custom' ? _pickRange(context) : model.select(item.$1),
                    ),
                ],
              ),
              if (model.period == 'season') ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final item in const [('bahor', 'Bahor'), ('yoz', 'Yoz'), ('kuz', 'Kuz'), ('qish', 'Qish')])
                      ChoiceChip(
                        label: Text(item.$2),
                        selected: model.season == item.$1,
                        selectedColor: TezColors.pinkSoft,
                        onSelected: (_) => model.selectSeason(item.$1),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Text(model.range.label, style: Theme.of(context).textTheme.titleLarge),
              Text(
                '${prettyDate(model.range.from)} — ${prettyDate(model.range.to)}',
                style: const TextStyle(color: TezColors.muted),
              ),
              const SizedBox(height: 14),
              if (model.loading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (model.error != null)
                ErrorPane(message: model.error!, onRetry: model.load)
              else if (model.report != null)
                _report(context, model.report!),
            ],
          ),
        );
      },
    );
  }

  Widget _report(BuildContext context, SalesReport report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            return GridView.count(
              crossAxisCount: wide ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: wide ? 1.45 : 1.25,
              children: [
                MoneyTile(label: 'Tushum', value: som(report.revenue), color: TezColors.yellowDeep),
                MoneyTile(label: 'Xarajat', value: som(report.expense), color: TezColors.pink),
                MoneyTile(label: 'Foyda', value: som(report.profit), color: TezColors.green),
                MoneyTile(label: 'Foyda foizi', value: percentText(report.profitPercent), color: TezColors.ink),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        Text(
          'Buyurtma: ${report.salesCount}   ·   Hali berilmagan: ${report.openCount}   ·   Bekor: ${report.cancelledCount}',
          style: const TextStyle(color: TezColors.muted),
        ),
        const SizedBox(height: 18),
        Text('Mahsulotlar sotuvi', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        if (report.products.isEmpty)
          const EmptyHint(
            icon: Icons.bar_chart,
            title: 'Bu davrda sotuv yo\'q',
            body: 'Buyurtma tushganda tushum, xarajat va foyda shu yerda chiqadi.',
          )
        else
          for (final product in report.products) ...[
            _product(product),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  Widget _product(ProductSales product) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TezColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TezColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
              Text('${product.quantity} ta', style: const TextStyle(fontWeight: FontWeight.w900, color: TezColors.pink)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _stat('Tushum', som(product.revenue)),
              _stat('Xarajat', som(product.expense)),
              _stat('Foyda', som(product.profit)),
              _stat('Foiz', percentText(product.profitPercent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: TezColors.muted, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final from = await showDatePicker(
      context: context,
      initialDate: model.customFrom ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      helpText: 'Boshlanish',
    );
    if (from == null || !context.mounted) return;
    final to = await showDatePicker(
      context: context,
      initialDate: model.customTo ?? from,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      helpText: 'Tugash',
    );
    if (to == null) return;
    await model.selectCustom(from, to);
  }
}
