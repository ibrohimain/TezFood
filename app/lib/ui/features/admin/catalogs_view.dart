import 'package:flutter/material.dart';

import '../../../domain/models.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'catalogs_view_model.dart';
import 'product_form_view.dart';

class CatalogsView extends StatefulWidget {
  const CatalogsView({super.key, required this.model});

  final CatalogsViewModel model;

  @override
  State<CatalogsView> createState() => _CatalogsViewState();
}

class _CatalogsViewState extends State<CatalogsView> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.model,
      builder: (context, _) {
        final model = widget.model;
        return Scaffold(
          body: model.loading
              ? const Center(child: CircularProgressIndicator())
              : model.error != null
                  ? ErrorPane(message: model.error!, onRetry: model.load)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                      children: [
                        const Text(
                          'Katalogni qo\'lda yarating va taomlarni shu yerga joylashtiring.',
                          style: TextStyle(color: TezColors.muted),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _name,
                                decoration: const InputDecoration(hintText: 'Yangi katalog, masalan Lavash'),
                                onSubmitted: (_) => _create(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(onPressed: _create, child: const Text('Qo\'shish')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (model.catalogs.isEmpty)
                          const EmptyHint(
                            icon: Icons.folder_open,
                            title: 'Katalog yo\'q',
                            body: 'Masalan: Lavash, Burger, Ichimliklar.',
                          )
                        else
                          for (var i = 0; i < model.catalogs.length; i++) ...[
                            _tile(context, model.catalogs[i], i, model.catalogs.length),
                            const SizedBox(height: 10),
                          ],
                      ],
                    ),
        );
      },
    );
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final error = await widget.model.create(name);
    if (!mounted) return;
    if (error == null) _name.clear();
    _toast(error);
  }

  Widget _tile(BuildContext context, Catalog catalog, int index, int total) {
    final count = widget.model.counts[catalog.id] ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: TezColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TezColors.line),
      ),
      child: Row(
        children: [
          Column(
            children: [
              IconButton(
                onPressed: index == 0 ? null : () => _act(widget.model.move(catalog, 'up')),
                icon: const Icon(Icons.keyboard_arrow_up),
              ),
              IconButton(
                onPressed: index == total - 1 ? null : () => _act(widget.model.move(catalog, 'down')),
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
            ],
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(catalog.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text('$count ta taom', style: const TextStyle(color: TezColors.muted)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Taom qo\'shish',
            onPressed: () async {
              final saved = await openProductForm(context, catalogId: catalog.id);
              if (saved == true) widget.model.load();
            },
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Nomini o\'zgartirish',
            onPressed: () => _rename(catalog),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'O\'chirish',
            onPressed: () => _act(widget.model.remove(catalog)),
            icon: const Icon(Icons.delete_outline, color: TezColors.pinkDeep),
          ),
        ],
      ),
    );
  }

  Future<void> _rename(Catalog catalog) async {
    final controller = TextEditingController(text: catalog.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Katalog nomi'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Saqlash')),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    await _act(widget.model.rename(catalog, name));
  }

  Future<void> _act(Future<String?> future) async {
    final error = await future;
    if (!mounted) return;
    _toast(error);
  }

  void _toast(String? error) {
    if (error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }
}
