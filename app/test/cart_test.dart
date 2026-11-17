import 'package:flutter_test/flutter_test.dart';
import 'package:tez_food/domain/models.dart';
import 'package:tez_food/ui/core/format.dart';
import 'package:tez_food/ui/features/cart/cart_model.dart';

Product sample(int id, int price) {
  return Product(
    id: id,
    catalogId: 1,
    name: 'Taom $id',
    image: null,
    ingredients: const [],
    cost: price ~/ 2,
    markup: price - price ~/ 2,
    price: price,
  );
}

void main() {
  test('savat jami narx va sonni hisoblaydi', () {
    final cart = CartModel();
    cart.setQuantity(sample(1, 32000), 2);
    cart.setQuantity(sample(2, 8000), 1);
    expect(cart.total, 72000);
    expect(cart.count, 3);
    cart.setQuantity(sample(1, 32000), 0);
    expect(cart.total, 8000);
    expect(cart.count, 1);
  });

  test('pul va foiz matni', () {
    expect(som(32000), "32 000 so'm");
    expect(som(-1500), "-1 500 so'm");
    expect(percentText(43.8), '43.8%');
    expect(percentText(50), '50%');
  });

  test('mavsum oralig\'i kuzni topadi', () {
    final range = rangeFor('kuz', DateTime(2026, 11, 17));
    expect(range.from, DateTime(2026, 9, 1));
    expect(range.to, DateTime(2026, 11, 30));
  });
}
