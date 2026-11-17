import 'package:flutter/foundation.dart';

import '../../../domain/models.dart';

class CartLine {
  CartLine({required this.product, required this.quantity});

  Product product;
  int quantity;

  int get total => product.price * quantity;
}

class CartModel extends ChangeNotifier {
  final List<CartLine> lines = [];

  int get count => lines.fold(0, (sum, line) => sum + line.quantity);

  int get total => lines.fold(0, (sum, line) => sum + line.total);

  int quantityOf(int productId) {
    for (final line in lines) {
      if (line.product.id == productId) return line.quantity;
    }
    return 0;
  }

  void setQuantity(Product product, int quantity) {
    final index = lines.indexWhere((line) => line.product.id == product.id);
    if (quantity <= 0) {
      if (index >= 0) lines.removeAt(index);
    } else if (index >= 0) {
      lines[index] = CartLine(product: product, quantity: quantity);
    } else {
      lines.add(CartLine(product: product, quantity: quantity));
    }
    notifyListeners();
  }

  void clear() {
    lines.clear();
    notifyListeners();
  }
}
