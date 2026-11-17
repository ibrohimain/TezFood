import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../data/repositories/tez_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../domain/models.dart';
import '../../core/geo.dart';
import '../../safe_notifier.dart';
import 'cart_model.dart';

class CartViewModel extends SafeNotifier {
  CartViewModel(this._repository, this.cart);

  final TezRepository _repository;
  final CartModel cart;

  String channel = 'zal';
  bool sending = false;
  bool locating = false;
  double? latitude;
  double? longitude;
  String addressHint = '';
  String? error;
  ShopOrder? placed;

  void setChannel(String value) {
    channel = value;
    error = null;
    if (value != 'yetkazish') {
      latitude = null;
      longitude = null;
      addressHint = '';
    }
    notifyListeners();
  }

  Future<void> locate() async {
    locating = true;
    error = null;
    notifyListeners();
    try {
      final point = await currentPosition();
      latitude = point.latitude;
      longitude = point.longitude;
      addressHint = await _addressFor(point);
    } catch (_) {
      latitude = null;
      longitude = null;
      error = 'Joylashuv aniqlanmadi. Manzilni o\'zingiz yozing.';
    } finally {
      locating = false;
      notifyListeners();
    }
  }

  Future<String> _addressFor(GeoPoint point) async {
    final fallback = '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': '${point.latitude}',
        'lon': '${point.longitude}',
        'accept-language': 'uz',
      });
      final response = await http.get(uri, headers: {
        'User-Agent': 'TEZFOOD/1.0',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return fallback;
      final data = jsonDecode(response.body);
      if (data is Map && data['display_name'] is String) {
        final name = (data['display_name'] as String).trim();
        if (name.length >= 5) return name;
      }
    } catch (_) {}
    return fallback;
  }

  Future<void> submit({required String phone, required String address}) async {
    if (cart.lines.isEmpty || sending) return;
    sending = true;
    error = null;
    notifyListeners();
    try {
      placed = await _repository.placeOrder(
        channel: channel,
        phone: phone.trim(),
        address: address.trim(),
        latitude: channel == 'yetkazish' ? latitude : null,
        longitude: channel == 'yetkazish' ? longitude : null,
        items: [
          for (final line in cart.lines) (productId: line.product.id, quantity: line.quantity),
        ],
      );
      cart.clear();
    } on ApiException catch (error) {
      this.error = error.message;
    } finally {
      sending = false;
      notifyListeners();
    }
  }
}
