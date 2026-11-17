import '../services/api_client.dart';
import '../../domain/models.dart';
import '../../ui/core/format.dart';
import '../../ui/session.dart';

class TezRepository {
  TezRepository(this._api, this._session);

  final ApiClient _api;
  final SessionModel _session;

  Future<List<Catalog>> catalogs() async {
    final data = await _api.get('/api/catalogs');
    return _list(data, Catalog.fromJson);
  }

  Future<Catalog> createCatalog(String name) async {
    final data = await _admin(() => _api.post('/api/catalogs', body: {'name': name}, auth: 'admin'));
    return Catalog.fromJson(_map(data));
  }

  Future<Catalog> renameCatalog(int id, String name) async {
    final data = await _admin(() => _api.put('/api/catalogs/$id', body: {'name': name}));
    return Catalog.fromJson(_map(data));
  }

  Future<void> deleteCatalog(int id) {
    return _admin(() async {
      await _api.delete('/api/catalogs/$id');
    });
  }

  Future<List<Catalog>> moveCatalog(int id, String direction) async {
    final data = await _admin(
      () => _api.post('/api/catalogs/$id/move', body: {'direction': direction}, auth: 'admin'),
    );
    return _list(data, Catalog.fromJson);
  }

  Future<List<Product>> products() async {
    final data = await _api.get('/api/products');
    return _list(data, Product.fromJson);
  }

  Future<Product> saveProduct(ProductDraft draft) async {
    final data = await _admin(() {
      if (draft.id == null) {
        return _api.post('/api/products', body: draft.toJson(), auth: 'admin');
      }
      return _api.put('/api/products/${draft.id}', body: draft.toJson());
    });
    return Product.fromJson(_map(data));
  }

  Future<void> deleteProduct(int id) {
    return _admin(() async {
      await _api.delete('/api/products/$id');
    });
  }

  Future<ShopOrder> placeOrder({
    required String channel,
    required String phone,
    required String address,
    required List<({int productId, int quantity})> items,
  }) async {
    final data = await _api.post('/api/orders', body: {
      'channel': channel,
      'phone': phone,
      'address': address,
      'items': [
        for (final item in items) {'productId': item.productId, 'quantity': item.quantity},
      ],
    });
    return ShopOrder.fromJson(_map(data));
  }

  Future<List<ShopOrder>> orders({String? status, DateTime? day}) async {
    final data = await _staff(() {
      return _api.get('/api/orders', auth: 'staff', query: {
        if (status != null) 'status': status,
        if (day != null) 'day': isoDate(day),
      });
    });
    return _list(data, ShopOrder.fromJson);
  }

  Future<ShopOrder> setStatus(int id, String status) async {
    final data = await _staff(() => _api.patch('/api/orders/$id', body: {'status': status}));
    return ShopOrder.fromJson(_map(data));
  }

  Future<SalesReport> report(DateTime from, DateTime to) async {
    final data = await _admin(() {
      return _api.get('/api/reports', auth: 'admin', query: {
        'from': isoDate(from),
        'to': isoDate(to),
      });
    });
    return SalesReport.fromJson(_map(data));
  }

  Future<void> login({required String role, required String pin}) async {
    final data = await _api.post('/api/auth/login', body: {'role': role, 'pin': pin});
    final token = _map(data)['token'] as String? ?? '';
    if (token.isEmpty) throw ApiException('PIN qabul qilinmadi');
    if (role == 'admin') {
      await _session.setAdmin(token);
    } else {
      await _session.setKassa(token);
    }
  }

  Future<void> logout({required bool admin}) async {
    try {
      await _api.post('/api/auth/logout', auth: admin ? 'admin' : 'staff');
    } catch (_) {}
    if (admin || _session.kassaToken == null) {
      await _session.clearAdmin();
    } else {
      await _session.clearKassa();
    }
  }

  Future<T> _admin<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException catch (error) {
      if (error.statusCode == 401) await _session.clearAdmin();
      rethrow;
    }
  }

  Future<T> _staff<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        if (_session.kassaToken == null) {
          await _session.clearAdmin();
        } else {
          await _session.clearKassa();
        }
      }
      rethrow;
    }
  }

  Map<String, dynamic> _map(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('Server javobi noto\'g\'ri');
  }

  List<T> _list<T>(dynamic data, T Function(Map<String, dynamic>) parse) {
    if (data is! List) throw ApiException('Server javobi noto\'g\'ri');
    return data.whereType<Map>().map((e) => parse(Map<String, dynamic>.from(e))).toList();
  }
}
