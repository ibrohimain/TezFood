import 'package:test/test.dart';
import 'package:tez_food_server/models.dart';
import 'package:tez_food_server/report.dart';

FoodOrder order({
  required DateTime at,
  required String status,
  required List<OrderItem> items,
  int id = 1,
}) {
  return FoodOrder(
    id: id,
    number: id,
    createdAt: at,
    status: status,
    channel: 'zal',
    phone: '',
    address: '',
    items: items,
  );
}

OrderItem item({
  required String name,
  required int qty,
  required int price,
  required int cost,
  int productId = 1,
}) {
  return OrderItem(
    productId: productId,
    name: name,
    quantity: qty,
    unitPrice: price,
    unitCost: cost,
  );
}

void main() {
  final from = DateTime(2026, 11, 1);
  final to = DateTime(2026, 11, 30);

  test('foyda tushumdan xarajatni ayiradi va bekor buyurtmani hisoblamaydi', () {
    final report = buildReport(
      [
        order(
          id: 1,
          at: DateTime(2026, 11, 17, 12),
          status: 'done',
          items: [
            item(name: 'Lavash', qty: 2, price: 32000, cost: 18000),
          ],
        ),
        order(
          id: 2,
          at: DateTime(2026, 11, 17, 13),
          status: 'cancelled',
          items: [
            item(name: 'Lavash', qty: 5, price: 32000, cost: 18000),
          ],
        ),
        order(
          id: 3,
          at: DateTime(2026, 10, 2),
          status: 'done',
          items: [
            item(name: 'Lavash', qty: 1, price: 32000, cost: 18000, productId: 1),
          ],
        ),
      ],
      from,
      to,
    );

    expect(report.revenue, 64000);
    expect(report.expense, 36000);
    expect(report.profit, 28000);
    expect(report.profitPercent, 43.8);
    expect(report.salesCount, 1);
    expect(report.cancelledCount, 1);
    expect(report.products.single.quantity, 2);
  });

  test('yangi buyurtma ham bugungi sotuvga kiradi', () {
    final report = buildReport(
      [
        order(
          at: DateTime(2026, 11, 17, 9),
          status: 'new',
          items: [
            item(name: 'Cola', qty: 1, price: 8000, cost: 4000, productId: 7),
            item(name: 'Fri', qty: 1, price: 12000, cost: 6000, productId: 6),
          ],
        ),
      ],
      DateTime(2026, 11, 17),
      DateTime(2026, 11, 17),
    );

    expect(report.revenue, 20000);
    expect(report.expense, 10000);
    expect(report.profit, 10000);
    expect(report.profitPercent, 50);
    expect(report.openCount, 1);
    expect(report.products, hasLength(2));
  });

  test('tushum nol bo\'lsa foiz nol', () {
    final report = buildReport([], from, to);
    expect(report.profit, 0);
    expect(report.profitPercent, 0);
  });

  test('kunlik raqam shu kundagi oxirgisidan keyin', () {
    final now = DateTime(2026, 11, 17, 18);
    final number = nextDailyNumber(
      [
        order(id: 4, at: DateTime(2026, 11, 17, 8), status: 'done', items: []),
        order(id: 9, at: DateTime(2026, 11, 16, 8), status: 'done', items: []),
      ],
      now,
    );
    expect(number, 5);
  });
}
