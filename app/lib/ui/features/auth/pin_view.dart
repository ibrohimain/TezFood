import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/tez_repository.dart';
import '../../../data/services/api_client.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

class PinView extends StatefulWidget {
  const PinView({super.key, required this.role});

  final String role;

  @override
  State<PinView> createState() => _PinViewState();
}

class _PinViewState extends State<PinView> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  bool get _admin => widget.role == 'admin';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _controller.text.trim();
    if (pin.length < 4 || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<TezRepository>().login(role: _admin ? 'admin' : 'kassa', pin: pin);
      if (!mounted) return;
      context.go(_admin ? '/admin' : '/kassa');
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _controller.clear();
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _type(String value) {
    if (_controller.text.length >= 8) return;
    _controller.text += value;
    setState(() => _error = null);
  }

  void _backspace() {
    final text = _controller.text;
    if (text.isEmpty) return;
    _controller.text = text.substring(0, text.length - 1);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const BrandLockup(compact: true)),
      body: SafeArea(
        child: PageWidth(
          maxWidth: 420,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(_admin ? 'Admin' : 'Kassa', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                _admin ? 'Taom va hisobot uchun PIN.' : 'Buyurtmalarni ko\'rish uchun PIN.',
                style: const TextStyle(color: TezColors.muted),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                obscureText: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(hintText: 'PIN'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: TezColors.pinkDeep, fontWeight: FontWeight.w700)),
              ],
              const SizedBox(height: 18),
              _pad(),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _controller.text.length >= 4 && !_busy ? _submit : null,
                child: _busy
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
                    : const Text('Kirish'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pad() {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'clear', '0', 'del'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.7,
      children: [
        for (final key in keys)
          OutlinedButton(
            onPressed: _busy
                ? null
                : () {
                    if (key == 'del') {
                      _backspace();
                    } else if (key == 'clear') {
                      _controller.clear();
                      setState(() {});
                    } else {
                      _type(key);
                    }
                  },
            child: Text(
              key == 'del' ? '←' : key == 'clear' ? 'C' : key,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
      ],
    );
  }
}
