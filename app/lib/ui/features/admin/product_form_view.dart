import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/tez_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/image_tools.dart';
import '../../../domain/models.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

Future<bool?> openProductForm(BuildContext context, {int? productId, int? catalogId}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => ProductFormView(productId: productId, initialCatalogId: catalogId),
    ),
  );
}

class ProductFormView extends StatefulWidget {
  const ProductFormView({super.key, this.productId, this.initialCatalogId});

  final int? productId;
  final int? initialCatalogId;

  @override
  State<ProductFormView> createState() => _ProductFormViewState();
}

class _IngredientRow {
  _IngredientRow({String name = '', String amount = ''})
      : name = TextEditingController(text: name),
        amount = TextEditingController(text: amount);

  final TextEditingController name;
  final TextEditingController amount;

  void dispose() {
    name.dispose();
    amount.dispose();
  }
}

class _ProductFormViewState extends State<ProductFormView> {
  final _name = TextEditingController();
  final _cost = TextEditingController(text: '0');
  final _markup = TextEditingController(text: '0');
  final List<_IngredientRow> _rows = [_IngredientRow()];
  List<Catalog> _catalogs = [];
  int? _catalogId;
  Uint8List? _photo;
  String? _existingImage;
  bool _clearImage = false;
  bool _loading = true;
  bool _saving = false;
  bool _filled = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cost.addListener(_refresh);
    _markup.addListener(_refresh);
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _cost.dispose();
    _markup.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  int get _costValue => int.tryParse(_cost.text) ?? 0;
  int get _markupValue => int.tryParse(_markup.text) ?? 0;
  int get _price => _costValue + _markupValue;

  Future<void> _load() async {
    final repo = context.read<TezRepository>();
    try {
      final catalogs = await repo.catalogs();
      Product? product;
      if (widget.productId != null) {
        final products = await repo.products();
        for (final item in products) {
          if (item.id == widget.productId) product = item;
        }
      }
      if (!mounted) return;
      setState(() {
        _catalogs = catalogs;
        _catalogId = product?.catalogId ?? widget.initialCatalogId ?? (catalogs.isEmpty ? null : catalogs.first.id);
        if (product != null && !_filled) {
          _name.text = product.name;
          _cost.text = '${product.cost}';
          _markup.text = '${product.markup}';
          _existingImage = product.image;
          for (final row in _rows) {
            row.dispose();
          }
          _rows
            ..clear()
            ..addAll(product.ingredients.map((item) => _IngredientRow(name: item.name, amount: item.amount)));
          if (_rows.isEmpty) _rows.add(_IngredientRow());
          _filled = true;
        }
        if (product == null && widget.productId != null) {
          _error = 'Taom topilmadi';
        }
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (picked == null) return;
    final raw = await picked.readAsBytes();
    final jpg = await compute(compressFoodPhoto, raw);
    if (!mounted) return;
    setState(() {
      _photo = jpg;
      _clearImage = false;
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (_catalogId == null) {
      setState(() => _error = 'Avval katalog yarating');
      return;
    }
    if (name.isEmpty) {
      setState(() => _error = 'Taom nomini yozing');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final ingredients = [
      for (final row in _rows)
        if (row.name.text.trim().isNotEmpty)
          Ingredient(name: row.name.text.trim(), amount: row.amount.text.trim()),
    ];
    final keepImage = _photo == null && !_clearImage;
    try {
      await context.read<TezRepository>().saveProduct(
            ProductDraft(
              id: widget.productId,
              catalogId: _catalogId!,
              name: name,
              ingredients: ingredients,
              cost: _costValue,
              markup: _markupValue,
              imageBase64: _photo == null ? '' : base64Encode(_photo!),
              keepImage: keepImage,
            ),
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final id = widget.productId;
    if (id == null) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Taom o\'chirilsinmi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Yo\'q')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('O\'chirish')),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    try {
      await context.read<TezRepository>().deleteProduct(id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.productId != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Taomni tahrirlash' : 'Taom qo\'shish')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : PageWidth(
              maxWidth: 760,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _imageBox(),
                  const SizedBox(height: 16),
                  const Text('Katalog', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  if (_catalogs.isEmpty)
                    const Text('Katalog yo\'q. Avval katalog yarating.', style: TextStyle(color: TezColors.pinkDeep))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final catalog in _catalogs)
                          ChoiceChip(
                            label: Text(catalog.name),
                            selected: _catalogId == catalog.id,
                            selectedColor: TezColors.yellow,
                            onSelected: (_) => setState(() => _catalogId = catalog.id),
                          ),
                      ],
                    ),
                  const SizedBox(height: 14),
                  TextField(controller: _name, decoration: const InputDecoration(hintText: 'Taom nomi')),
                  const SizedBox(height: 16),
                  const Text('Masalliqlar', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  for (var i = 0; i < _rows.length; i++) ...[
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _rows[i].name,
                            decoration: const InputDecoration(hintText: 'Masalliq'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _rows[i].amount,
                            decoration: const InputDecoration(hintText: 'Miqdor'),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            final row = _rows.removeAt(i);
                            setState(() {
                              if (_rows.isEmpty) _rows.add(_IngredientRow());
                            });
                            WidgetsBinding.instance.addPostFrameCallback((_) => row.dispose());
                          },
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _rows.add(_IngredientRow())),
                      icon: const Icon(Icons.add),
                      label: const Text('Masalliq'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 560;
                      final cost = TextField(
                        controller: _cost,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(labelText: 'Jami xarajat, so\'m'),
                      );
                      final markup = TextField(
                        controller: _markup,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(labelText: 'Ustama, so\'m'),
                      );
                      if (stacked) {
                        return Column(children: [cost, const SizedBox(height: 10), markup]);
                      }
                      return Row(children: [Expanded(child: cost), const SizedBox(width: 10), Expanded(child: markup)]);
                    },
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: TezColors.pinkSoft,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sotuv narxi', style: TextStyle(fontWeight: FontWeight.w700)),
                        Text(som(_price), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                        Text(
                          'Foyda foizi ${percentText(_price == 0 ? 0 : (_markupValue * 1000 / _price).round() / 10)}',
                          style: const TextStyle(color: TezColors.ink),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: const TextStyle(color: TezColors.pinkDeep, fontWeight: FontWeight.w700)),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
                        : const Text('Saqlash'),
                  ),
                  if (editing) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(onPressed: _saving ? null : _delete, child: const Text('O\'chirish')),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _imageBox() {
    final hasNew = _photo != null;
    final hasOld = _existingImage != null && !_clearImage && !hasNew;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: AspectRatio(
            aspectRatio: 1.8,
            child: hasNew
                ? Image.memory(_photo!, fit: BoxFit.cover)
                : hasOld
                    ? ProductPhoto(fileName: _existingImage)
                    : const ProductPhoto(),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.photo), label: const Text('Rasm')),
            if (hasNew || hasOld)
              TextButton(
                onPressed: () => setState(() {
                  _photo = null;
                  _clearImage = true;
                }),
                child: const Text('Rasmni olib tashlash'),
              ),
          ],
        ),
      ],
    );
  }
}
