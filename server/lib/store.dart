import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'models.dart';
import 'report.dart';

class StoreException implements Exception {
  StoreException(this.message);
  final String message;
  @override
  String toString() => message;
}

class Store {
  Store(this.root);

  final Directory root;
  final Map<String, String> tokens = {};

  List<Catalog> catalogs = [];
  List<Product> products = [];
  List<FoodOrder> orders = [];
  int _nextId = 1;
  Future<void> _lock = Future.value();

  File get _file => File(p.join(root.path, 'store.json'));
  Directory get uploads => Directory(p.join(root.path, 'uploads'));

  Future<T> transaction<T>(Future<T> Function() action) {
    final next = _lock.then((_) => action());
    _lock = next.then((_) {}, onError: (_) {});
    return next;
  }

  Future<void> init() async {
    if (!root.existsSync()) root.createSync(recursive: true);
    if (!uploads.existsSync()) uploads.createSync(recursive: true);
    if (!_file.existsSync()) {
      _seed();
      await _persist();
      return;
    }
    final raw = jsonDecode(await _file.readAsString()) as Map<String, dynamic>;
    _nextId = raw['nextId'] as int? ?? 1;
    catalogs = (raw['catalogs'] as List<dynamic>? ?? [])
        .map((e) => Catalog.fromJson(e as Map<String, dynamic>))
        .toList();
    products = (raw['products'] as List<dynamic>? ?? [])
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
    orders = (raw['orders'] as List<dynamic>? ?? [])
        .map((e) => FoodOrder.fromJson(e as Map<String, dynamic>))
        .toList();
    final savedTokens = raw['tokens'] as Map<String, dynamic>? ?? {};
    tokens
      ..clear()
      ..addAll(savedTokens.map((key, value) => MapEntry(key, value as String)));
  }

  Future<void> _persist() async {
    final payload = {
      'nextId': _nextId,
      'tokens': tokens,
      'catalogs': catalogs.map((e) => e.toJson()).toList(),
      'products': products.map((e) => e.toJson()).toList(),
      'orders': orders.map((e) => e.toJson()).toList(),
    };
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    if (_file.existsSync()) _file.deleteSync();
    tmp.renameSync(_file.path);
  }

  int _id() => _nextId++;

  void _seed() {
    catalogs = [
      Catalog(id: _id(), name: 'Lavash', sortOrder: 0),
      Catalog(id: _id(), name: 'Burger', sortOrder: 1),
      Catalog(id: _id(), name: 'Gazaklar', sortOrder: 2),
      Catalog(id: _id(), name: 'Ichimliklar', sortOrder: 3),
    ];

    Product food({
      required int catalogId,
      required String name,
      required List<Ingredient> ingredients,
      required int cost,
      required int markup,
    }) {
      return Product(
        id: _id(),
        catalogId: catalogId,
        name: name,
        image: null,
        ingredients: ingredients,
        cost: cost,
        markup: markup,
      );
    }

    Ingredient piece(String name, double quantity, int price, [String unit = 'g']) {
      return Ingredient(name: name, quantity: quantity, unit: unit, price: price);
    }

    products = [
      food(
        catalogId: catalogs[0].id,
        name: 'Tovuqli lavash',
        ingredients: [
          piece('Lavash xamiri', 80, 3000),
          piece('Tovuq go\'shti', 120, 9000),
          piece('Pomidor', 30, 2000),
          piece('Bodring', 30, 2000),
          piece('Sous', 20, 2000),
        ],
        cost: 18000,
        markup: 14000,
      ),
      food(
        catalogId: catalogs[0].id,
        name: 'Go\'shtli lavash',
        ingredients: [
          piece('Lavash xamiri', 80, 3000),
          piece('Mol go\'shti', 130, 12000),
          piece('Piyoz', 20, 1000),
          piece('Pomidor', 30, 2000),
          piece('Sous', 20, 4000),
        ],
        cost: 22000,
        markup: 16000,
      ),
      food(
        catalogId: catalogs[1].id,
        name: 'Chizburger',
        ingredients: [
          piece('Burger noni', 80, 3000),
          piece('Kotlet', 100, 10000),
          piece('Sir', 20, 4000),
          piece('Salat bargi', 10, 1000),
          piece('Sous', 15, 2000),
        ],
        cost: 20000,
        markup: 14000,
      ),
      food(
        catalogId: catalogs[1].id,
        name: 'Tovuqli burger',
        ingredients: [
          piece('Burger noni', 80, 3000),
          piece('Tovuq kotlet', 110, 10000),
          piece('Salat bargi', 10, 1000),
          piece('Sous', 15, 3000),
        ],
        cost: 17000,
        markup: 13000,
      ),
      food(
        catalogId: catalogs[2].id,
        name: 'Hot-dog',
        ingredients: [
          piece('Hot-dog noni', 70, 2000),
          piece('Sosiska', 80, 4000),
          piece('Ketchup', 15, 1500),
          piece('Xantal', 5, 500),
        ],
        cost: 8000,
        markup: 7000,
      ),
      food(
        catalogId: catalogs[2].id,
        name: 'Kartoshka fri',
        ingredients: [
          piece('Kartoshka', 150, 4000),
          piece('Yog\'', 20, 1500),
          piece('Tuz', 1, 500),
        ],
        cost: 6000,
        markup: 6000,
      ),
      food(
        catalogId: catalogs[3].id,
        name: 'Cola 0.5',
        ingredients: [
          piece('Gazlangan ichimlik', 500, 4000),
        ],
        cost: 4000,
        markup: 4000,
      ),
      food(
        catalogId: catalogs[3].id,
        name: 'Mevali sok',
        ingredients: [
          piece('Sok', 330, 5000),
        ],
        cost: 5000,
        markup: 4000,
      ),
    ];

    final now = DateTime.now();
    FoodOrder sample({
      required int daysAgo,
      required String status,
      required String channel,
      required List<OrderItem> items,
      String phone = '',
      String address = '',
    }) {
      final created = now.subtract(Duration(days: daysAgo, hours: daysAgo == 0 ? 1 : 0));
      final number = orders.where((o) {
            final c = o.createdAt;
            return c.year == created.year &&
                c.month == created.month &&
                c.day == created.day;
          }).length +
          1;
      final order = FoodOrder(
        id: _id(),
        number: number,
        createdAt: created,
        status: status,
        channel: channel,
        phone: phone,
        address: address,
        items: items,
      );
      orders.add(order);
      return order;
    }

    OrderItem line(Product product, int quantity) {
      return OrderItem(
        productId: product.id,
        name: product.name,
        quantity: quantity,
        unitPrice: product.price,
        unitCost: product.cost,
      );
    }

    sample(
      daysAgo: 0,
      status: 'done',
      channel: 'zal',
      items: [line(products[0], 2), line(products[6], 1)],
    );
    sample(
      daysAgo: 0,
      status: 'done',
      channel: 'olib_ketish',
      items: [line(products[2], 1), line(products[5], 1)],
    );
    sample(
      daysAgo: 0,
      status: 'new',
      channel: 'yetkazish',
      phone: '90 123 45 67',
      address: 'Chilonzor 12-kvartal, 8-uy',
      items: [line(products[4], 2), line(products[6], 2)],
    );
    sample(
      daysAgo: 0,
      status: 'cancelled',
      channel: 'zal',
      items: [line(products[1], 1)],
    );
    sample(
      daysAgo: 3,
      status: 'done',
      channel: 'zal',
      items: [line(products[0], 1), line(products[3], 1)],
    );
    sample(
      daysAgo: 20,
      status: 'done',
      channel: 'zal',
      items: [line(products[2], 2)],
    );
  }

  List<Catalog> listCatalogs() {
    final copy = [...catalogs]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return copy;
  }

  List<Product> listProducts() {
    final copy = [...products]..sort((a, b) => a.name.compareTo(b.name));
    return copy;
  }

  Catalog? catalogById(int id) {
    for (final catalog in catalogs) {
      if (catalog.id == id) return catalog;
    }
    return null;
  }

  Product? productById(int id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  Future<Catalog> addCatalog(String name) {
    return transaction(() async {
      final order = catalogs.fold<int>(0, (max, c) => c.sortOrder > max ? c.sortOrder : max) + 1;
      final catalog = Catalog(id: _id(), name: name, sortOrder: catalogs.isEmpty ? 0 : order);
      catalogs.add(catalog);
      await _persist();
      return catalog;
    });
  }

  Future<Catalog> renameCatalog(int id, String name) {
    return transaction(() async {
      final index = catalogs.indexWhere((c) => c.id == id);
      if (index < 0) throw StoreException('Katalog topilmadi');
      final current = catalogs[index];
      final next = Catalog(id: current.id, name: name, sortOrder: current.sortOrder);
      catalogs[index] = next;
      await _persist();
      return next;
    });
  }

  Future<void> deleteCatalog(int id) {
    return transaction(() async {
      if (catalogById(id) == null) throw StoreException('Katalog topilmadi');
      if (products.any((item) => item.catalogId == id)) {
        throw StoreException(
          'Katalogda taomlar bor. Avval ularni boshqa katalogga o\'tkazing yoki o\'chiring.',
        );
      }
      catalogs.removeWhere((c) => c.id == id);
      await _persist();
    });
  }

  Future<void> moveCatalog(int id, int delta) {
    return transaction(() async {
      final sorted = listCatalogs();
      final index = sorted.indexWhere((c) => c.id == id);
      final target = index + delta;
      if (index < 0 || target < 0 || target >= sorted.length) return;
      final a = sorted[index];
      final b = sorted[target];
      catalogs = catalogs.map((c) {
        if (c.id == a.id) return Catalog(id: c.id, name: c.name, sortOrder: b.sortOrder);
        if (c.id == b.id) return Catalog(id: c.id, name: c.name, sortOrder: a.sortOrder);
        return c;
      }).toList();
      await _persist();
    });
  }

  Future<Product> saveProduct({
    int? id,
    required int catalogId,
    required String name,
    required List<Ingredient> ingredients,
    required int cost,
    required int markup,
    String? image,
    bool keepImage = false,
  }) {
    return transaction(() async {
      if (catalogById(catalogId) == null) {
        throw StoreException('Katalog topilmadi');
      }
      if (id == null) {
        final product = Product(
          id: _id(),
          catalogId: catalogId,
          name: name,
          image: image,
          ingredients: ingredients,
          cost: cost,
          markup: markup,
        );
        products.add(product);
        await _persist();
        return product;
      }
      final index = products.indexWhere((item) => item.id == id);
      if (index < 0) throw StoreException('Taom topilmadi');
      final previous = products[index];
      final nextImage = keepImage ? previous.image : image;
      if (!keepImage && previous.image != null && previous.image != image) {
        _deleteImage(previous.image!);
      }
      final product = Product(
        id: id,
        catalogId: catalogId,
        name: name,
        image: nextImage,
        ingredients: ingredients,
        cost: cost,
        markup: markup,
      );
      products[index] = product;
      await _persist();
      return product;
    });
  }

  Future<void> deleteProduct(int id) {
    return transaction(() async {
      final product = productById(id);
      if (product == null) throw StoreException('Taom topilmadi');
      if (product.image != null) _deleteImage(product.image!);
      products.removeWhere((item) => item.id == id);
      await _persist();
    });
  }

  void _deleteImage(String name) {
    final file = File(p.join(uploads.path, name));
    if (file.existsSync()) file.deleteSync();
  }

  Future<String> saveImage(List<int> bytes, String ext) {
    return transaction(() async {
      final safeExt = ext == 'png' ? 'png' : 'jpg';
      final name = '${_id()}.$safeExt';
      await File(p.join(uploads.path, name)).writeAsBytes(bytes, flush: true);
      return name;
    });
  }

  Future<FoodOrder> placeOrder({
    required String channel,
    required String phone,
    required String address,
    double? latitude,
    double? longitude,
    required List<({int productId, int quantity})> lines,
  }) {
    return transaction(() async {
      final items = <OrderItem>[];
      for (final line in lines) {
        final product = productById(line.productId);
        if (product == null) {
          throw StoreException('Tanlangan taom menyuda yo\'q');
        }
        items.add(
          OrderItem(
            productId: product.id,
            name: product.name,
            quantity: line.quantity,
            unitPrice: product.price,
            unitCost: product.countedCost,
          ),
        );
      }
      final now = DateTime.now();
      final order = FoodOrder(
        id: _id(),
        number: nextDailyNumber(orders, now),
        createdAt: now,
        status: 'new',
        channel: channel,
        phone: phone,
        address: address,
        latitude: latitude,
        longitude: longitude,
        items: items,
      );
      orders.add(order);
      await _persist();
      return order;
    });
  }

  List<FoodOrder> listOrders({String? status, DateTime? day}) {
    final copy = orders.where((order) {
      if (status != null && status.isNotEmpty && order.status != status) return false;
      if (day != null) {
        final created = order.createdAt.toLocal();
        if (created.year != day.year || created.month != day.month || created.day != day.day) {
          return false;
        }
      }
      return true;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return copy;
  }

  Future<FoodOrder> setStatus(int id, String status) {
    return transaction(() async {
      final index = orders.indexWhere((o) => o.id == id);
      if (index < 0) throw StoreException('Buyurtma topilmadi');
      final current = orders[index];
      final next = FoodOrder(
        id: current.id,
        number: current.number,
        createdAt: current.createdAt,
        status: status,
        channel: current.channel,
        phone: current.phone,
        address: current.address,
        latitude: current.latitude,
        longitude: current.longitude,
        items: current.items,
      );
      orders[index] = next;
      await _persist();
      return next;
    });
  }

  Future<String> issueToken(String role) {
    return transaction(() async {
      final token = _id().toRadixString(16) + DateTime.now().microsecondsSinceEpoch.toRadixString(16);
      tokens[token] = role;
      await _persist();
      return token;
    });
  }

  Future<void> revokeToken(String token) {
    return transaction(() async {
      tokens.remove(token);
      await _persist();
    });
  }
}
