class Ingredient {
  Ingredient({required this.name, required this.amount});

  final String name;
  final String amount;

  Map<String, dynamic> toJson() => {'name': name, 'amount': amount};

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] as String? ?? '',
      amount: json['amount'] as String? ?? '',
    );
  }
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
    required this.items,
  });

  final int id;
  final int number;
  final DateTime createdAt;
  final String status;
  final String channel;
  final String phone;
  final String address;
  final List<OrderItem> items;

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'createdAt': createdAt.toIso8601String(),
        'status': status,
        'channel': channel,
        'phone': phone,
        'address': address,
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
      items: raw
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
