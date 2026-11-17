import 'package:flutter/material.dart';

import '../../config.dart';
import 'format.dart';
import 'theme.dart';

class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final mark = compact ? 36.0 : 52.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: mark,
          height: mark,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: TezColors.yellow,
            borderRadius: BorderRadius.circular(compact ? 12 : 16),
          ),
          child: Text(
            'TEZ',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: compact ? 12 : 16,
              color: TezColors.ink,
              letterSpacing: -0.4,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'FOOD',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: compact ? 22 : 32,
            color: TezColors.pink,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class ProductPhoto extends StatelessWidget {
  const ProductPhoto({super.key, this.fileName});

  final String? fileName;

  @override
  Widget build(BuildContext context) {
    final url = ApiConfig.imageUrl(fileName);
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFE082), Color(0xFFFF8A9B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        if (url != null)
          Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => const SizedBox.shrink(),
          ),
        if (url == null) const Center(child: Icon(Icons.restaurant, color: Colors.white, size: 42)),
      ],
    );
  }
}

class QtyStepper extends StatelessWidget {
  const QtyStepper({super.key, required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TezColors.yellowSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _button(Icons.remove, () => onChanged(value - 1)),
          SizedBox(
            width: 36,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
          _button(Icons.add, () => onChanged(value + 1)),
        ],
      ),
    );
  }

  Widget _button(IconData icon, VoidCallback onPressed) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      color: TezColors.ink,
    );
  }
}

class MoneyTile extends StatelessWidget {
  const MoneyTile({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TezColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TezColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const Spacer(),
            Text(label, style: const TextStyle(color: TezColors.muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: TezColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyHint extends StatelessWidget {
  const EmptyHint({super.key, required this.title, required this.body, required this.icon});

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: TezColors.pink),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(body, textAlign: TextAlign.center, style: const TextStyle(color: TezColors.muted)),
          ],
        ),
      ),
    );
  }
}

class ErrorPane extends StatelessWidget {
  const ErrorPane({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: TezColors.pink),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: TezColors.muted)),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Qayta urinish')),
          ],
        ),
      ),
    );
  }
}

class PriceText extends StatelessWidget {
  const PriceText({super.key, required this.value, this.size = 16});

  final int value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      som(value),
      style: TextStyle(color: TezColors.pink, fontWeight: FontWeight.w800, fontSize: size),
    );
  }
}

class PageWidth extends StatelessWidget {
  const PageWidth({super.key, required this.maxWidth, required this.child});

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
