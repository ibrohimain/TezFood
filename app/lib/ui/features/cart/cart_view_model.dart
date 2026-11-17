import '../../../data/repositories/tez_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../domain/models.dart';
import '../../safe_notifier.dart';
import 'cart_model.dart';

class CartViewModel extends SafeNotifier {
  CartViewModel(this._repository, this.cart);

  final TezRepository _repository;
  final CartModel cart;

  String channel = 'zal';
  bool sending = false;
  String? error;
  ShopOrder? placed;

  void setChannel(String value) {
    channel = value;
    error = null;
    notifyListeners();
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
