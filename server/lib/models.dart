class Ingredient {
  Ingredient({
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

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'price': price,
        'amount': amount,
      };

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    final measured = measureOf(
      amount: json['amount'] as String? ?? '',
      quantity: json['quantity'],
      unit: json['unit'] as String?,
    );
    final rawPrice = json['price'];
    return Ingredient(
      name: json['name'] as String? ?? '',
      quantity: measured.$1,
      unit: measured.$2,
      price: rawPrice is num ? rawPrice.round() : int.tryParse('$rawPrice') ?? 0,
    );
  }
}

(double, String) measureOf({required String amount, Object? quantity, String? unit}) {
  if (quantity is num) {
    return (quantity.toDouble(), unit == 'kg' ? 'kg' : 'g');
  }
  if (quantity is String) {
    final parsed = double.tryParse(quantity.trim().replaceAll(',', '.'));
    if (parsed != null) {
      return (parsed, unit == 'kg' ? 'kg' : 'g');
    }
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
  Catalog({required this.id, required this.name, required this.sortOrder});

  final int id;
  final String name;
  final int sortOrder;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sortOrder': sortOrder,
      };

  factory Catalog.fromJson(Map<String, dynamic> json) {
    return Catalog(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}

class Product {
  Product({
    required this.id,
    required this.catalogId,
    required this.name,
    required this.image,
    required this.ingredients,
    required this.cost,
    required this.markup,
  });

  final int id;
  final int catalogId;
  final String name;
  final String? image;
  final List<Ingredient> ingredients;
  final int cost;
  final int markup;

  int get price => cost + markup;

  int get ingredientCost => ingredients.fold(0, (sum, item) => sum + item.price);

  /// Masalliq narxi yozilgan bo'lsa xarajat shu yig'indi. Aks holda qo'lda kiritilgan xarajat.
  int get countedCost => ingredientCost > 0 ? ingredientCost : cost;

  Map<String, dynamic> toJson() => {
        'id': id,
        'catalogId': catalogId,
        'name': name,
        'image': image,
        'ingredients': ingredients.map((e) => e.toJson()).toList(),
        'cost': cost,
        'markup': markup,
        'price': price,
      };

  factory Product.fromJson(Map<String, dynamic> json) {
    final raw = json['ingredients'] as List<dynamic>? ?? [];
    return Product(
      id: json['id'] as int,
      catalogId: json['catalogId'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      image: json['image'] as String?,
      ingredients: raw
          .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      cost: json['cost'] as int? ?? 0,
      markup: json['markup'] as int? ?? 0,
    );
  }
}

class OrderItem {
  OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.unitCost,
  });

  final int productId;
  final String name;
  final int quantity;
  final int unitPrice;
  final int unitCost;

  int get revenue => unitPrice * quantity;
  int get expense => unitCost * quantity;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'unitCost': unitCost,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      unitPrice: json['unitPrice'] as int? ?? 0,
      unitCost: json['unitCost'] as int? ?? 0,
    );
  }
}

class FoodOrder {
  FoodOrder({
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
  final List<OrderItem> items;

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'createdAt': createdAt.toIso8601String(),
        'status': status,
        'channel': channel,
        'phone': phone,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'items': items.map((e) => e.toJson()).toList(),
      };

  /// Kassa ekrani: faqat taom nomi va soni, narx yo'q.
  Map<String, dynamic> toKassaJson() => {
        'id': id,
        'number': number,
        'createdAt': createdAt.toIso8601String(),
        'status': status,
        'channel': channel,
        'phone': phone,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'items': items
            .map((e) => {'name': e.name, 'quantity': e.quantity})
            .toList(),
      };

  factory FoodOrder.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List<dynamic>? ?? [];
    return FoodOrder(
      id: json['id'] as int,
      number: json['number'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: json['status'] as String? ?? 'new',
      channel: json['channel'] as String? ?? 'zal',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      items: raw
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

double? _asDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}
