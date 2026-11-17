import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../domain/models.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'cart_model.dart';
import 'cart_view_model.dart';

class CartView extends StatefulWidget {
  const CartView({super.key, required this.model});

  final CartViewModel model;

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  Future<void> _locate() async {
    await widget.model.locate();
    if (!mounted) return;
    final hint = widget.model.addressHint;
    if (hint.isNotEmpty) _address.text = hint;
  }

  final _phone = TextEditingController();
  final _address = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();
    return ListenableBuilder(
      listenable: widget.model,
      builder: (context, _) {
        final placed = widget.model.placed;
        return Scaffold(
          appBar: AppBar(title: Text(placed == null ? 'Buyurtma' : 'Yuborildi')),
          body: PageWidth(
            maxWidth: 720,
            child: placed != null ? _success(context, placed) : _form(context, cart),
          ),
        );
      },
    );
  }

  Widget _success(BuildContext context, ShopOrder order) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: TezColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: TezColors.line),
          ),
          child: Column(
            children: [
              const Icon(Icons.check_circle, color: TezColors.green, size: 64),
              const SizedBox(height: 12),
              Text('Buyurtma #${order.number}', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text(
                'Kassaga tushdi. To\'lov so\'ralmaydi — hammasi naqd.',
                textAlign: TextAlign.center,
                style: TextStyle(color: TezColors.muted),
              ),
              const SizedBox(height: 16),
              for (final item in order.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                      Text('× ${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              const Divider(height: 28),
              Row(
                children: [
                  const Text('Jami', style: TextStyle(fontWeight: FontWeight.w800)),
                  const Spacer(),
                  PriceText(value: order.total, size: 20),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: () => context.go('/menu'), child: const Text('Menyuga qaytish')),
      ],
    );
  }

  Widget _form(BuildContext context, CartModel cart) {
    if (cart.lines.isEmpty) {
      return const EmptyHint(
        icon: Icons.shopping_bag_outlined,
        title: 'Savat bo\'sh',
        body: 'Menyudan taom tanlang.',
      );
    }
    final model = widget.model;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (final line in cart.lines) ...[
          _line(context, cart, line),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        const Text('Qayerga?', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final item in const [
              ('zal', 'Zal'),
              ('olib_ketish', 'Olib ketish'),
              ('yetkazish', 'Yetkazish'),
            ])
              ChoiceChip(
                label: Text(item.$2),
                selected: model.channel == item.$1,
                selectedColor: TezColors.yellow,
                onSelected: (selected) {
                  if (!selected) return;
                  model.setChannel(item.$1);
                  if (item.$1 == 'yetkazish') _locate();
                },
              ),
          ],
        ),
        if (model.channel == 'yetkazish') ...[
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: 'Telefon'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _address,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Manzil'),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: model.locating ? null : _locate,
              icon: model.locating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location),
              label: Text(model.locating ? 'Joylashuv aniqlanmoqda' : 'Joylashuvni aniqlash'),
            ),
          ),
          if (model.latitude != null)
            const Text(
              'Nuqta saqlandi. Kassa buyurtmani qabul qilganda shu yerga yo\'l ochiladi.',
              style: TextStyle(color: TezColors.muted),
            ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TezColors.yellowSoft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'To\'lov naqd. Ilova pul so\'ramaydi.',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              PriceText(value: cart.total, size: 18),
            ],
          ),
        ),
        if (model.error != null) ...[
          const SizedBox(height: 10),
          Text(model.error!, style: const TextStyle(color: TezColors.pinkDeep, fontWeight: FontWeight.w700)),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: model.sending
              ? null
              : () => model.submit(phone: _phone.text, address: _address.text),
          child: model.sending
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
              : const Text('Buyurtma berish'),
        ),
      ],
    );
  }

  Widget _line(BuildContext context, CartModel cart, CartLine line) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TezColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TezColors.line),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(width: 64, height: 64, child: ProductPhoto(fileName: line.product.image)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.product.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                PriceText(value: line.total),
              ],
            ),
          ),
          QtyStepper(
            value: line.quantity,
            onChanged: (next) => cart.setQuantity(line.product, next.clamp(0, 99)),
          ),
        ],
      ),
    );
  }
}
