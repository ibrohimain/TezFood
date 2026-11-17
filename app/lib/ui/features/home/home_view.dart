import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageWidth(
          maxWidth: 1040,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 840;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                children: [
                  const BrandLockup(),
                  const SizedBox(height: 12),
                  Text(
                    'Tez, issiq, mazali',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Mijoz menyudan tanlaydi, buyurtma kassaga tushadi, admin esa taom va foydani ko\'radi. To\'lov hammasi naqd.',
                    style: TextStyle(color: TezColors.muted, fontSize: 16),
                  ),
                  const SizedBox(height: 28),
                  if (wide)
                    Row(
                      children: [
                        Expanded(child: _door(context, _customer)),
                        const SizedBox(width: 14),
                        Expanded(child: _door(context, _kassa)),
                        const SizedBox(width: 14),
                        Expanded(child: _door(context, _admin)),
                      ],
                    )
                  else ...[
                    _door(context, _customer),
                    const SizedBox(height: 12),
                    _door(context, _kassa),
                    const SizedBox(height: 12),
                    _door(context, _admin),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _door(BuildContext context, _Door door) {
    return Material(
      color: TezColors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push(door.path),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: TezColors.line),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: door.tint,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(door.icon, color: door.iconColor),
                ),
                const SizedBox(height: 18),
                Text(door.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(door.body, style: const TextStyle(color: TezColors.muted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Door {
  const _Door({
    required this.title,
    required this.body,
    required this.path,
    required this.icon,
    required this.tint,
    required this.iconColor,
  });

  final String title;
  final String body;
  final String path;
  final IconData icon;
  final Color tint;
  final Color iconColor;
}

const _customer = _Door(
  title: 'Menyu',
  body: 'Taomni ko\'ring, sonini belgilang va buyurtma bering.',
  path: '/menu',
  icon: Icons.restaurant_menu,
  tint: TezColors.yellowSoft,
  iconColor: TezColors.ink,
);

const _kassa = _Door(
  title: 'Kassa',
  body: 'Kelgan buyurtma: qaysi taom va nechta.',
  path: '/kassa',
  icon: Icons.point_of_sale,
  tint: TezColors.pinkSoft,
  iconColor: TezColors.pinkDeep,
);

const _admin = _Door(
  title: 'Admin',
  body: 'Taom, katalog, kunlik sotuv va foyda.',
  path: '/admin',
  icon: Icons.admin_panel_settings,
  tint: Color(0xFFF3EBE4),
  iconColor: TezColors.ink,
);
