import 'package:flutter/material.dart';

import '../../../domain/models.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'product_form_view.dart';
import 'products_view_model.dart';

class ProductsView extends StatelessWidget {
  const ProductsView({super.key, required this.model});

  final ProductsViewModel model;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: TezColors.yellow,
            foregroundColor: TezColors.ink,
            onPressed: () async {
              final saved = await openProductForm(context);
              if (saved == true) model.load();
            },
            icon: const Icon(Icons.add),
            label: const Text('Taom'),
          ),
          body: model.loading
              ? const Center(child: CircularProgressIndicator())
              : model.error != null
                  ? ErrorPane(message: model.error!, onRetry: model.load)
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: TextField(
                            onChanged: model.search,
                            decoration: const InputDecoration(
                              hintText: 'Taom qidirish',
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                        ),
                        Expanded(
                          child: model.visible.isEmpty
                              ? const EmptyHint(
                                  icon: Icons.fastfood,
                                  title: 'Taom yo\'q',
                                  body: 'Katalog ochib, taom qo\'shing: nomi, xarajat, ustama va rasm.',
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                                  itemCount: model.visible.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final product = model.visible[index];
                                    return _tile(context, product);
                                  },
                                ),
                        ),
                      ],
                    ),
        );
      },
    );
  }

  Widget _tile(BuildContext context, Product product) {
    final sold = model.soldToday[product.id] ?? 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TezColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TezColors.line),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(width: 72, height: 72, child: ProductPhoto(fileName: product.image)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text(model.catalogName(product.catalogId), style: const TextStyle(color: TezColors.muted)),
                const SizedBox(height: 4),
                Text(
                  'Xarajat ${som(product.cost)}  ·  Ustama ${som(product.markup)}',
                  style: const TextStyle(fontSize: 12, color: TezColors.muted),
                ),
                Row(
                  children: [
                    PriceText(value: product.price),
                    const SizedBox(width: 8),
                    Text('Bugun $sold ta', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Tahrirlash',
            onPressed: () async {
              final saved = await openProductForm(context, productId: product.id);
              if (saved == true) model.load();
            },
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'O\'chirish',
            onPressed: () => _confirmDelete(context, product),
            icon: const Icon(Icons.delete_outline, color: TezColors.pinkDeep),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Product product) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Taom o\'chirilsinmi?'),
        content: Text(product.name),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Yo\'q')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('O\'chirish')),
        ],
      ),
    );
    if (yes != true || !context.mounted) return;
    final error = await model.remove(product);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}
