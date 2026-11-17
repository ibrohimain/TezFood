import 'package:flutter/material.dart';

import '../../../domain/models.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'product_form_view.dart';
import 'products_view_model.dart';

class ProductsView extends StatefulWidget {
  const ProductsView({super.key, required this.model});

  final ProductsViewModel model;

  @override
  State<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<ProductsView> {
  /// `list` — tepadan pastga; `grid` — ilova kabi kartochkalar.
  String _layout = 'grid';

  ProductsViewModel get model => widget.model;

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
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  onChanged: model.search,
                                  decoration: const InputDecoration(
                                    hintText: 'Taom qidirish',
                                    prefixIcon: Icon(Icons.search),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              _LayoutToggle(
                                layout: _layout,
                                onChanged: (value) => setState(() => _layout = value),
                              ),
                            ],
                          ),
                        ),
                        Expanded(child: _content(context)),
                      ],
                    ),
        );
      },
    );
  }

  Widget _content(BuildContext context) {
    if (model.visible.isEmpty) {
      return const EmptyHint(
        icon: Icons.fastfood,
        title: 'Taom yo\'q',
        body: 'Katalog ochib, taom qo\'shing: nomi, xarajat, ustama va rasm.',
      );
    }
    if (_layout == 'list') {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        itemCount: model.visible.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _ListTile(
          product: model.visible[index],
          catalog: model.catalogName(model.visible[index].catalogId),
          sold: model.soldToday[model.visible[index].id] ?? 0,
          onEdit: () => _edit(context, model.visible[index]),
          onDelete: () => _confirmDelete(context, model.visible[index]),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        // Tor ekranda 2 ta, keng ekranda 5–6 ta.
        final maxExtent = constraints.maxWidth >= 1400
            ? 220.0
            : constraints.maxWidth >= 1100
                ? 240.0
                : constraints.maxWidth >= 800
                    ? 260.0
                    : 190.0;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxExtent,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.68,
          ),
          itemCount: model.visible.length,
          itemBuilder: (context, index) {
            final product = model.visible[index];
            return _ProductCard(
              product: product,
              catalog: model.catalogName(product.catalogId),
              sold: model.soldToday[product.id] ?? 0,
              onTap: () => _edit(context, product),
              onDelete: () => _confirmDelete(context, product),
            );
          },
        );
      },
    );
  }

  Future<void> _edit(BuildContext context, Product product) async {
    final saved = await openProductForm(context, productId: product.id);
    if (saved == true) model.load();
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

class _LayoutToggle extends StatelessWidget {
  const _LayoutToggle({required this.layout, required this.onChanged});

  final String layout;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TezColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TezColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.view_agenda_outlined, 'list', 'Ro\'yxat'),
          _btn(Icons.grid_view_rounded, 'grid', 'Kartochka'),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, String value, String tip) {
    final selected = layout == value;
    return IconButton(
      tooltip: tip,
      onPressed: () => onChanged(value),
      icon: Icon(icon, color: selected ? TezColors.ink : TezColors.muted),
      style: IconButton.styleFrom(
        backgroundColor: selected ? TezColors.yellow : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _ListTile extends StatelessWidget {
  const _ListTile({
    required this.product,
    required this.catalog,
    required this.sold,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final String catalog;
  final int sold;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TezColors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onEdit,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: TezColors.line),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 96,
                    height: 96,
                    child: ProductPhoto(fileName: product.image),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                      Text(catalog, style: const TextStyle(color: TezColors.muted)),
                      const SizedBox(height: 4),
                      Text(
                        'Xarajat ${som(product.cost)}  ·  Ustama ${som(product.markup)}',
                        style: const TextStyle(fontSize: 12, color: TezColors.muted),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          PriceText(value: product.price),
                          const SizedBox(width: 10),
                          Text('Bugun $sold ta', style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Tahrirlash',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'O\'chirish',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: TezColors.pinkDeep),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.catalog,
    required this.sold,
    required this.onTap,
    required this.onDelete,
  });

  final Product product;
  final String catalog;
  final int sold;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TezColors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: TezColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
                      child: ProductPhoto(fileName: product.image),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: TezColors.white.withValues(alpha: 0.92),
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: 'O\'chirish',
                          visualDensity: VisualDensity.compact,
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline, color: TezColors.pinkDeep, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (catalog.isNotEmpty)
                        Text(catalog, style: const TextStyle(color: TezColors.muted, fontSize: 12)),
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Xarajat ${som(product.cost)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: TezColors.muted, fontSize: 12),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(child: PriceText(value: product.price, size: 15)),
                          Text(
                            '$sold ta',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: TezColors.pink),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
