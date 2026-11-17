import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/tez_repository.dart';
import '../../../domain/models.dart';
import '../../core/format.dart';
import '../../core/open_link.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'kassa_view_model.dart';

String navigatorUrl(ShopOrder order) {
  final lat = order.latitude;
  final lng = order.longitude;
  if (lat != null && lng != null) {
    return 'https://yandex.uz/maps/?rtext=~$lat,$lng&rtt=auto';
  }
  final query = order.address.trim().isEmpty ? 'Toshkent' : order.address.trim();
  return 'https://yandex.uz/maps/?text=${Uri.encodeComponent(query)}';
}

class KassaView extends StatelessWidget {
  const KassaView({super.key, required this.model, this.embedded = false});

  final KassaViewModel model;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Kassa'),
            automaticallyImplyLeading: !embedded,
            actions: [
              IconButton(tooltip: 'Yangilash', onPressed: model.refresh, icon: const Icon(Icons.refresh)),
              if (!embedded)
                IconButton(
                  tooltip: 'Chiqish',
                  onPressed: () async {
                    await context.read<TezRepository>().logout(admin: false);
                    if (context.mounted) context.go('/');
                  },
                  icon: const Icon(Icons.logout),
                ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Yangi')),
                      ButtonSegment(value: true, label: Text('Bugungi tayyor')),
                    ],
                    selected: {model.showDone},
                    onSelectionChanged: (value) => model.show(value.first),
                  ),
                ),
              ),
              Expanded(child: _body()),
            ],
          ),
        );
      },
    );
  }

  Widget _body() {
    if (model.loading && model.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (model.error != null && model.orders.isEmpty) {
      return ErrorPane(message: model.error!, onRetry: model.refresh);
    }
    if (model.orders.isEmpty) {
      return EmptyHint(
        icon: Icons.receipt_long,
        title: model.showDone ? 'Bugun tayyor bo\'lgan buyurtma yo\'q' : 'Yangi buyurtma yo\'q',
        body: 'Mijoz menyudan buyurtma berganda shu yerda chiqadi.',
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: wide ? 420 : 700,
            mainAxisExtent: 360,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: model.orders.length,
          itemBuilder: (context, index) => _OrderCard(order: model.orders[index], model: model),
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.model});

  final ShopOrder order;
  final KassaViewModel model;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TezColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: order.status == 'new' ? TezColors.pink : TezColors.line, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('#${order.number}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
              const SizedBox(width: 8),
              Text(prettyTime(order.createdAt), style: const TextStyle(color: TezColors.muted)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: order.channel == 'yetkazish' ? TezColors.pinkSoft : TezColors.yellowSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(channelLabel(order.channel), style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (order.channel == 'yetkazish') ...[
            const SizedBox(height: 6),
            Text('${order.phone}  ·  ${order.address}', style: const TextStyle(color: TezColors.muted)),
          ],
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: [
                for (final item in order.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                        ),
                        Text(
                          '× ${item.quantity}',
                          style: const TextStyle(color: TezColors.pink, fontWeight: FontWeight.w900, fontSize: 20),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (order.channel == 'yetkazish' && order.status != 'cancelled') ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => openLink(navigatorUrl(order)),
                icon: const Icon(Icons.navigation_outlined),
                label: const Text('Qabul qilish · Yo\'l'),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (order.status == 'new')
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => model.mark(order, 'done'),
                    child: const Text('Tayyor'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => model.mark(order, 'cancelled'),
                  child: const Text('Bekor'),
                ),
              ],
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: () => model.mark(order, 'new'), child: const Text('Navbatga qaytarish')),
            ),
        ],
      ),
    );
  }
}
