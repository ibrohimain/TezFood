import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../domain/models.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../cart/cart_model.dart';
import 'menu_view_model.dart';

class MenuView extends StatelessWidget {
  const MenuView({super.key, required this.model});

  final MenuViewModel model;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const BrandLockup(compact: true),
            actions: [
              IconButton(
                tooltip: 'Savat',
                onPressed: () => context.push('/cart'),
                icon: Badge(
                  isLabelVisible: cart.count > 0,
                  label: Text('${cart.count}'),
                  backgroundColor: TezColors.pink,
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          bottomNavigationBar: cart.count == 0
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: FilledButton(
                      onPressed: () => context.push('/cart'),
                      child: Text('${cart.count} ta  ·  ${som(cart.total)}  ·  Buyurtma'),
                    ),
                  ),
                ),
          body: _body(context, cart),
        );
      },
    );
  }

  Widget _body(BuildContext context, CartModel cart) {
    if (model.loading) return const Center(child: CircularProgressIndicator());
    if (model.error != null) return ErrorPane(message: model.error!, onRetry: model.load);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            onChanged: model.search,
            decoration: const InputDecoration(
              hintText: 'Taom yoki masalliq qidirish',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _chip(context, 'Barchasi', model.catalogId == null, () => model.selectCatalog(null)),
              for (final catalog in model.catalogs) ...[
                const SizedBox(width: 8),
                _chip(
                  context,
                  catalog.name,
                  model.catalogId == catalog.id,
                  () => model.selectCatalog(catalog.id),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: model.visible.isEmpty
              ? const EmptyHint(
                  icon: Icons.restaurant,
                  title: 'Taom topilmadi',
                  body: 'Boshqa katalogni tanlang yoki qidiruvni tozalang.',
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: model.visible.length,
                  itemBuilder: (context, index) {
                    final product = model.visible[index];
                    return _ProductCard(
                      product: product,
                      catalog: model.catalogName(product.catalogId),
                      quantity: cart.quantityOf(product.id),
                      onTap: () => _openProduct(context, product, cart),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _chip(BuildContext context, String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: TezColors.yellow,
      labelStyle: const TextStyle(fontWeight: FontWeight.w700, color: TezColors.ink),
      side: const BorderSide(color: TezColors.line),
      backgroundColor: TezColors.white,
    );
  }

  Future<void> _openProduct(BuildContext context, Product product, CartModel cart) {
    var quantity = cart.quantityOf(product.id);
    if (quantity == 0) quantity = 1;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TezColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(color: TezColors.line, borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: AspectRatio(aspectRatio: 1.7, child: ProductPhoto(fileName: product.image)),
                  ),
                  const SizedBox(height: 16),
                  Text(product.name, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  PriceText(value: product.price, size: 22),
                  const SizedBox(height: 16),
                  const Text('Masalliqlar', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  if (product.ingredients.isEmpty)
                    const Text('Masalliqlar ko\'rsatilmagan', style: TextStyle(color: TezColors.muted))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final item in product.ingredients)
                          Chip(
                            label: Text(item.label),
                            backgroundColor: TezColors.yellowSoft,
                            side: BorderSide.none,
                          ),
                      ],
                    ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Text('Soni', style: TextStyle(fontWeight: FontWeight.w800)),
                      const Spacer(),
                      QtyStepper(
                        value: quantity,
                        onChanged: (next) {
                          if (next < 1 || next > 99) return;
                          setState(() => quantity = next);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      cart.setQuantity(product, quantity);
                      Navigator.pop(context);
                    },
                    child: Text('Savatga  ·  ${som(product.price * quantity)}'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.catalog,
    required this.quantity,
    required this.onTap,
  });

  final Product product;
  final String catalog;
  final int quantity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final preview = product.ingredients.take(2).map((item) => item.name).join(', ');
    return Material(
      color: TezColors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: quantity > 0 ? TezColors.pink : TezColors.line, width: quantity > 0 ? 1.6 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
                  child: ProductPhoto(fileName: product.image),
                ),
              ),
              Padding(
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
                    if (preview.isNotEmpty)
                      Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: TezColors.muted, fontSize: 12),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: PriceText(value: product.price)),
                        if (quantity > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: TezColors.pink,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$quantity',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
