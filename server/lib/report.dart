import 'models.dart';

class ProductSales {
  ProductSales({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.revenue,
    required this.expense,
  });

  final int productId;
  final String name;
  final int quantity;
  final int revenue;
  final int expense;

  int get profit => revenue - expense;

  int get netProfit => profit;

  double get profitPercent =>
      revenue == 0 ? 0 : (profit * 1000 / revenue).round() / 10;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'quantity': quantity,
        'revenue': revenue,
        'expense': expense,
        'profit': profit,
        'netProfit': netProfit,
        'profitPercent': profitPercent,
      };
}

class SalesReport {
  SalesReport({
    required this.salesCount,
    required this.openCount,
    required this.cancelledCount,
    required this.revenue,
    required this.expense,
    required this.products,
  });

  final int salesCount;
  final int openCount;
  final int cancelledCount;
  final int revenue;
  final int expense;
  final List<ProductSales> products;

  int get profit => revenue - expense;

  int get netProfit => profit;

  int get soldQuantity => products.fold(0, (sum, item) => sum + item.quantity);

  double get profitPercent =>
      revenue == 0 ? 0 : (profit * 1000 / revenue).round() / 10;

  Map<String, dynamic> toJson() => {
        'salesCount': salesCount,
        'soldQuantity': soldQuantity,
        'openCount': openCount,
        'cancelledCount': cancelledCount,
        'revenue': revenue,
        'expense': expense,
        'profit': profit,
        'netProfit': netProfit,
        'profitPercent': profitPercent,
        'products': products.map((e) => e.toJson()).toList(),
      };
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool inRange(DateTime created, DateTime from, DateTime to) {
  final local = created.toLocal();
  final start = DateTime(from.year, from.month, from.day);
  final end = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
  return !local.isBefore(start) && !local.isAfter(end);
}

/// Sotuv hisobi: bekor qilinmagan buyurtmalar (yangi va berilgan).
SalesReport buildReport(List<FoodOrder> orders, DateTime from, DateTime to) {
  final ranged = orders.where((o) => inRange(o.createdAt, from, to)).toList();
  final cancelled = ranged.where((o) => o.status == 'cancelled').length;
  final open = ranged.where((o) => o.status == 'new').length;
  final counted = ranged.where((o) => o.status != 'cancelled').toList();

  final byProduct = <int, ProductSales>{};
  var revenue = 0;
  var expense = 0;

  for (final order in counted) {
    for (final item in order.items) {
      revenue += item.revenue;
      expense += item.expense;
      final current = byProduct[item.productId];
      if (current == null) {
        byProduct[item.productId] = ProductSales(
          productId: item.productId,
          name: item.name,
          quantity: item.quantity,
          revenue: item.revenue,
          expense: item.expense,
        );
      } else {
        byProduct[item.productId] = ProductSales(
          productId: item.productId,
          name: item.name,
          quantity: current.quantity + item.quantity,
          revenue: current.revenue + item.revenue,
          expense: current.expense + item.expense,
        );
      }
    }
  }

  final products = byProduct.values.toList()
    ..sort((a, b) {
      final byQty = b.quantity.compareTo(a.quantity);
      if (byQty != 0) return byQty;
      return a.name.compareTo(b.name);
    });

  return SalesReport(
    salesCount: counted.length,
    openCount: open,
    cancelledCount: cancelled,
    revenue: revenue,
    expense: expense,
    products: products,
  );
}

int nextDailyNumber(List<FoodOrder> orders, DateTime now) {
  final today = orders.where((o) => _sameDay(o.createdAt.toLocal(), now.toLocal()));
  var maxNumber = 0;
  for (final order in today) {
    if (order.number > maxNumber) maxNumber = order.number;
  }
  return maxNumber + 1;
}
