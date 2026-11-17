import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'models.dart';
import 'report.dart';
import 'store.dart';

class Api {
  Api({
    required this.store,
    required this.adminPin,
    required this.kassaPin,
  });

  final Store store;
  final String adminPin;
  final String kassaPin;

  Router get router {
    final router = Router();
    router.get('/api/health', (_) => _json({'ok': true, 'name': 'TEZ FOOD'}));
    router.post('/api/auth/login', _login);
    router.post('/api/auth/logout', _logout);

    router.get('/api/catalogs', (_) => _json(store.listCatalogs().map((e) => e.toJson()).toList()));
    router.post('/api/catalogs', _createCatalog);
    router.put('/api/catalogs/<id>', _renameCatalog);
    router.delete('/api/catalogs/<id>', _deleteCatalog);
    router.post('/api/catalogs/<id>/move', _moveCatalog);

    router.get('/api/products', (_) => _json(store.listProducts().map((e) => e.toJson()).toList()));
    router.post('/api/products', (request) => _saveProduct(request));
    router.put('/api/products/<id>', (request, id) => _saveProduct(request, id: id));
    router.delete('/api/products/<id>', _deleteProduct);

    router.post('/api/orders', _placeOrder);
    router.get('/api/orders', _listOrders);
    router.patch('/api/orders/<id>', _setStatus);

    router.get('/api/reports', _report);
    return router;
  }

  Future<Response> _login(Request request) async {
    final body = await _readMap(request);
    final role = body['role'] as String? ?? '';
    final pin = body['pin'] as String? ?? '';
    if (role == 'admin' && pin == adminPin) {
      final token = await store.issueToken('admin');
      return _json({'token': token, 'role': 'admin'});
    }
    if (role == 'kassa' && pin == kassaPin) {
      final token = await store.issueToken('kassa');
      return _json({'token': token, 'role': 'kassa'});
    }
    return _error(401, 'PIN noto\'g\'ri');
  }

  Future<Response> _logout(Request request) async {
    final token = _token(request);
    if (token != null) await store.revokeToken(token);
    return _json({'ok': true});
  }

  Future<Response> _createCatalog(Request request) async {
    final denied = _require(request, {'admin'});
    if (denied != null) return denied;
    final body = await _readMap(request);
    final name = _name(body['name'], label: 'Katalog nomi');
    final catalog = await store.addCatalog(name);
    return _json(catalog.toJson(), status: 201);
  }

  Future<Response> _renameCatalog(Request request, String id) async {
    final denied = _require(request, {'admin'});
    if (denied != null) return denied;
    final body = await _readMap(request);
    final name = _name(body['name'], label: 'Katalog nomi');
    final catalog = await store.renameCatalog(_id(id), name);
    return _json(catalog.toJson());
  }

  Future<Response> _deleteCatalog(Request request, String id) async {
    final denied = _require(request, {'admin'});
    if (denied != null) return denied;
    await store.deleteCatalog(_id(id));
    return _json({'ok': true});
  }

  Future<Response> _moveCatalog(Request request, String id) async {
    final denied = _require(request, {'admin'});
    if (denied != null) return denied;
    final body = await _readMap(request);
    final direction = body['direction'] as String? ?? '';
    final delta = direction == 'up' ? -1 : direction == 'down' ? 1 : 0;
    if (delta == 0) return _error(400, 'Yo\'nalish noto\'g\'ri');
    await store.moveCatalog(_id(id), delta);
    return _json(store.listCatalogs().map((e) => e.toJson()).toList());
  }

  Future<Response> _saveProduct(Request request, {String? id}) async {
    final denied = _require(request, {'admin'});
    if (denied != null) return denied;
    final body = await _readMap(request);
    final name = _name(body['name'], label: 'Taom nomi', max: 80);
    final catalogId = _money(body['catalogId'], label: 'Katalog');
    final cost = _money(body['cost'], label: 'Xarajat');
    final markup = _money(body['markup'], label: 'Ustama');
    if (cost > 100000000 || markup > 100000000) {
      return _error(400, 'Summa juda katta');
    }
    final ingredients = _ingredients(body['ingredients']);
    String? image;
    var keepImage = true;
    if (body.containsKey('imageBase64')) {
      keepImage = false;
      final raw = body['imageBase64'];
      if (raw is String && raw.trim().isNotEmpty) {
        image = await _storeImage(raw, body['imageExt'] as String? ?? 'jpg');
      }
    }
    final product = await store.saveProduct(
      id: id == null ? null : _id(id),
      catalogId: catalogId,
      name: name,
      ingredients: ingredients,
      cost: cost,
      markup: markup,
      image: image,
      keepImage: keepImage && id != null,
    );
    return _json(product.toJson(), status: id == null ? 201 : 200);
  }

  Future<String> _storeImage(String raw, String ext) async {
    final cleaned = raw.contains(',') && raw.startsWith('data:')
        ? raw.substring(raw.indexOf(',') + 1)
        : raw.trim();
    List<int> bytes;
    try {
      bytes = base64Decode(cleaned);
    } on FormatException {
      throw StoreException('Rasm formati noto\'g\'ri');
    }
    if (bytes.length > 2500000) {
      throw StoreException('Rasm 2.5 MB dan kichik bo\'lsin');
    }
    final safe = ext.toLowerCase() == 'png' ? 'png' : 'jpg';
    return store.saveImage(bytes, safe);
  }

  Future<Response> _deleteProduct(Request request, String id) async {
    final denied = _require(request, {'admin'});
    if (denied != null) return denied;
    await store.deleteProduct(_id(id));
    return _json({'ok': true});
  }

  Future<Response> _placeOrder(Request request) async {
    final body = await _readMap(request);
    final channel = body['channel'] as String? ?? 'zal';
    if (channel != 'zal' && channel != 'olib_ketish' && channel != 'yetkazish') {
      return _error(400, 'Buyurtma turi noto\'g\'ri');
    }
    final phone = (body['phone'] as String? ?? '').trim();
    final address = (body['address'] as String? ?? '').trim();
    if (channel == 'yetkazish') {
      final digits = phone.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 9) return _error(400, 'Yetkazish uchun telefon kiriting');
      if (address.length < 5) return _error(400, 'Yetkazish manzilini kiriting');
    }
    final rawLines = body['items'];
    if (rawLines is! List || rawLines.isEmpty) {
      return _error(400, 'Kamida bitta taom tanlang');
    }
    if (rawLines.length > 40) return _error(400, 'Juda ko\'p taom');
    final lines = <({int productId, int quantity})>[];
    for (final raw in rawLines) {
      if (raw is! Map) return _error(400, 'Buyurtma tarkibi noto\'g\'ri');
      final productId = _money(raw['productId'], label: 'Taom');
      final quantity = _money(raw['quantity'], label: 'Soni');
      if (quantity < 1 || quantity > 99) {
        return _error(400, 'Soni 1 dan 99 gacha bo\'lsin');
      }
      lines.add((productId: productId, quantity: quantity));
    }
    final order = await store.placeOrder(
      channel: channel,
      phone: phone,
      address: address,
      lines: lines,
    );
    return _json(order.toJson(), status: 201);
  }

  Future<Response> _listOrders(Request request) async {
    final denied = _require(request, {'admin', 'kassa'});
    if (denied != null) return denied;
    final params = request.url.queryParameters;
    final orders = store.listOrders(status: params['status'], day: _date(params['day']));
    return _json(orders.map((e) => e.toKassaJson()).toList());
  }

  Future<Response> _setStatus(Request request, String id) async {
    final denied = _require(request, {'admin', 'kassa'});
    if (denied != null) return denied;
    final body = await _readMap(request);
    final status = body['status'] as String? ?? '';
    if (status != 'new' && status != 'done' && status != 'cancelled') {
      return _error(400, 'Holat noto\'g\'ri');
    }
    final order = await store.setStatus(_id(id), status);
    return _json(order.toKassaJson());
  }

  Future<Response> _report(Request request) async {
    final denied = _require(request, {'admin'});
    if (denied != null) return denied;
    final params = request.url.queryParameters;
    final from = _date(params['from']);
    final to = _date(params['to']);
    if (from == null || to == null) {
      return _error(400, 'Sana from va to ko\'rinishida yyyy-MM-dd bo\'lsin');
    }
    if (to.isBefore(from)) return _error(400, 'Tugash sanasi boshlanishidan oldin');
    final report = buildReport(store.orders, from, to);
    return _json({
      'from': _stamp(from),
      'to': _stamp(to),
      ...report.toJson(),
    });
  }

  Response? _require(Request request, Set<String> roles) {
    final token = _token(request);
    final role = token == null ? null : store.tokens[token];
    if (role == null || !roles.contains(role)) {
      return _error(401, 'Bu bo\'lim uchun PIN kiriting');
    }
    return null;
  }

  String? _token(Request request) {
    final header = request.headers['authorization'];
    if (header == null) return null;
    final lower = header.toLowerCase();
    if (!lower.startsWith('bearer ')) return null;
    return header.substring(7).trim();
  }

  Future<Map<String, dynamic>> _readMap(Request request) async {
    final text = await request.readAsString();
    if (text.trim().isEmpty) return {};
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw StoreException('So\'rov noto\'g\'ri');
    }
    return decoded;
  }

  String _name(Object? value, {required String label, int max = 40}) {
    final name = (value as String? ?? '').trim();
    if (name.isEmpty) throw StoreException('$label yozilmagan');
    if (name.length > max) throw StoreException('$label $max ta belgidan oshmasin');
    return name;
  }

  int _money(Object? value, {required String label}) {
    if (value is int) {
      if (value < 0) throw StoreException('$label manfiy bo\'lmasin');
      return value;
    }
    if (value is num) {
      if (value < 0) throw StoreException('$label manfiy bo\'lmasin');
      return value.round();
    }
    throw StoreException('$label raqam bo\'lsin');
  }

  List<Ingredient> _ingredients(Object? raw) {
    if (raw == null) return [];
    if (raw is! List) throw StoreException('Masalliqlar ro\'yxati noto\'g\'ri');
    if (raw.length > 30) throw StoreException('Masalliqlar 30 tadan oshmasin');
    final items = <Ingredient>[];
    for (final entry in raw) {
      if (entry is! Map) throw StoreException('Masalliq noto\'g\'ri');
      final name = (entry['name'] as String? ?? '').trim();
      final amount = (entry['amount'] as String? ?? '').trim();
      if (name.isEmpty) continue;
      items.add(Ingredient(name: name, amount: amount));
    }
    return items;
  }

  int _id(String raw) {
    final id = int.tryParse(raw);
    if (id == null) throw StoreException('Raqam noto\'g\'ri');
    return id;
  }

  DateTime? _date(String? raw) {
    if (raw == null || raw.length != 10) return null;
    final parts = raw.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime(year, month, day);
  }

  String _stamp(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  Response _json(Object body, {int status = 200}) {
    return Response(
      status,
      body: jsonEncode(body),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  Response _error(int status, String message) {
    return _json({'error': message}, status: status);
  }
}

Handler apiErrors(Handler inner) {
  return (Request request) async {
    try {
      return await inner(request);
    } on StoreException catch (error) {
      return Response(
        400,
        body: jsonEncode({'error': error.message}),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException {
      return Response(
        400,
        body: jsonEncode({'error': 'So\'rovni o\'qib bo\'lmadi'}),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
  };
}
