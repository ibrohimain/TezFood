class Ingredient {
  const Ingredient({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.price,
  });

  final String name;
  final double quantity;
  final String unit;
  final int price;

  String get amount {
    if (quantity <= 0) return '';
    final text = quantity == quantity.roundToDouble()
        ? quantity.toStringAsFixed(0)
        : quantity.toStringAsFixed(2);
    return '$text $unit';
  }

  String get label => amount.isEmpty ? name : '$name · $amount';

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    final measured = _measureOf(
      amount: json['amount'] as String? ?? '',
      quantity: json['quantity'],
      unit: json['unit'] as String?,
    );
    return Ingredient(
      name: json['name'] as String? ?? '',
      quantity: measured.$1,
      unit: measured.$2,
      price: _asInt(json['price']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'price': price,
        'amount': amount,
      };
}

(double, String) _measureOf({required String amount, Object? quantity, String? unit}) {
  if (quantity is num) {
    return (quantity.toDouble(), unit == 'kg' ? 'kg' : 'g');
  }
  if (quantity is String) {
    final parsed = double.tryParse(quantity.trim().replaceAll(',', '.'));
    if (parsed != null) return (parsed, unit == 'kg' ? 'kg' : 'g');
  }
  final lower = amount.toLowerCase();
  final hasKg = RegExp(r'(^|[^a-z])kg\b').hasMatch(lower);
  final hasGram = RegExp(r'(^|[^a-z])g\b').hasMatch(lower);
  if (!hasKg && !hasGram) return (0, 'g');
  final match = RegExp(r'(\d+(?:[.,]\d+)?)').firstMatch(amount);
  final value = match == null ? 0.0 : double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 0;
  return (value, hasKg ? 'kg' : 'g');
}

class Catalog {
  const Catalog({required this.id, required this.name, required this.sortOrder});

  final int id;
  final String name;
  final int sortOrder;

  factory Catalog.fromJson(Map<String, dynamic> json) {
    return Catalog(
      id: _asInt(json['id']),
      name: json['name'] as String? ?? '',
      sortOrder: _asInt(json['sortOrder']),
    );
  }
}

class Product {
  const Product({
    required this.id,
    required this.catalogId,
    required this.name,
    required this.image,
    required this.ingredients,
    required this.cost,
    required this.markup,
    required this.price,
  });

  final int id;
  final int catalogId;
  final String name;
  final String? image;
  final List<Ingredient> ingredients;
  final int cost;
  final int markup;
  final int price;

  int get profit => price - cost;

  double get profitPercent => price == 0 ? 0 : (profit * 1000 / price).round() / 10;

  factory Product.fromJson(Map<String, dynamic> json) {
    final raw = json['ingredients'] as List<dynamic>? ?? [];
    final cost = _asInt(json['cost']);
    final markup = _asInt(json['markup']);
    return Product(
      id: _asInt(json['id']),
      catalogId: _asInt(json['catalogId']),
      name: json['name'] as String? ?? '',
      image: json['image'] as String?,
      ingredients: raw
          .whereType<Map>()
          .map((e) => Ingredient.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      cost: cost,
      markup: markup,
      price: json['price'] == null ? cost + markup : _asInt(json['price']),
    );
  }
}

class ProductDraft {
  const ProductDraft({
    this.id,
    required this.catalogId,
    required this.name,
    required this.ingredients,
    required this.cost,
    required this.markup,
    this.imageBase64,
    this.keepImage = true,
  });

  final int? id;
  final int catalogId;
  final String name;
  final List<Ingredient> ingredients;
  final int cost;
  final int markup;
  final String? imageBase64;
  final bool keepImage;

  Map<String, dynamic> toJson() => {
        'catalogId': catalogId,
        'name': name,
        'ingredients': ingredients.map((e) => e.toJson()).toList(),
        'cost': cost,
        'markup': markup,
        if (!keepImage) 'imageBase64': imageBase64 ?? '',
        if (!keepImage) 'imageExt': 'jpg',
      };
}

class OrderLine {
  const OrderLine({required this.name, required this.quantity, this.unitPrice, this.unitCost});

  final String name;
  final int quantity;
  final int? unitPrice;
  final int? unitCost;

  factory OrderLine.fromJson(Map<String, dynamic> json) {
    return OrderLine(
      name: json['name'] as String? ?? '',
      quantity: _asInt(json['quantity']),
      unitPrice: json['unitPrice'] == null ? null : _asInt(json['unitPrice']),
      unitCost: json['unitCost'] == null ? null : _asInt(json['unitCost']),
    );
  }
}

class ShopOrder {
  const ShopOrder({
    required this.id,
    required this.number,
    required this.createdAt,
    required this.status,
    required this.channel,
    required this.phone,
    required this.address,
    this.latitude,
    this.longitude,
    required this.items,
  });

  final int id;
  final int number;
  final DateTime createdAt;
  final String status;
  final String channel;
  final String phone;
  final String address;
  final double? latitude;
  final double? longitude;
  final List<OrderLine> items;

  int get total => items.fold(0, (sum, line) => sum + (line.unitPrice ?? 0) * line.quantity);

  factory ShopOrder.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List<dynamic>? ?? [];
    return ShopOrder(
      id: _asInt(json['id']),
      number: _asInt(json['number']),
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      status: json['status'] as String? ?? 'new',
      channel: json['channel'] as String? ?? 'zal',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      items: raw
          .whereType<Map>()
          .map((e) => OrderLine.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class ProductSales {
  const ProductSales({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.revenue,
    required this.expense,
    required this.profit,
    required this.profitPercent,
  });

  final int productId;
  final String name;
  final int quantity;
  final int revenue;
  final int expense;
  final int profit;
  final double profitPercent;

  int get netProfit => profit;

  factory ProductSales.fromJson(Map<String, dynamic> json) {
    return ProductSales(
      productId: _asInt(json['productId']),
      name: json['name'] as String? ?? '',
      quantity: _asInt(json['quantity']),
      revenue: _asInt(json['revenue']),
      expense: _asInt(json['expense']),
      profit: _asInt(json['profit']),
      profitPercent: (json['profitPercent'] as num?)?.toDouble() ?? 0,
    );
  }
}

class SalesReport {
  const SalesReport({
    required this.from,
    required this.to,
    required this.salesCount,
    required this.openCount,
    required this.cancelledCount,
    required this.revenue,
    required this.expense,
    required this.profit,
    required this.profitPercent,
    required this.products,
  });

  final String from;
  final String to;
  final int salesCount;
  final int openCount;
  final int cancelledCount;
  final int revenue;
  final int expense;
  final int profit;
  final double profitPercent;
  final List<ProductSales> products;

  int get netProfit => profit;

  int get soldQuantity => products.fold(0, (sum, item) => sum + item.quantity);

  factory SalesReport.fromJson(Map<String, dynamic> json) {
    final raw = json['products'] as List<dynamic>? ?? [];
    return SalesReport(
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      salesCount: _asInt(json['salesCount']),
      openCount: _asInt(json['openCount']),
      cancelledCount: _asInt(json['cancelledCount']),
      revenue: _asInt(json['revenue']),
      expense: _asInt(json['expense']),
      profit: _asInt(json['profit']),
      profitPercent: (json['profitPercent'] as num?)?.toDouble() ?? 0,
      products: raw
          .whereType<Map>()
          .map((e) => ProductSales.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse('$value') ?? 0;
}

double? _asDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}
