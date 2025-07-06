class Cart {
  final String userId;
  final Map<String, CartItem> items;
  final double totalAmount;

  Cart({required this.userId, required this.items, required this.totalAmount});

  Cart.fromJson(Map<dynamic, dynamic> json)
    : userId = json['userId'] as String,
      items = (json['items'] as Map<dynamic, dynamic>).map(
        (key, value) => MapEntry(
          key.toString(),
          CartItem.fromJson(value as Map<dynamic, dynamic>),
        ),
      ),
      totalAmount = json['totalAmount'] as double;

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
    'userId': userId,
    'items': items.map((key, value) => MapEntry(key, value.toJson())),
    'totalAmount': totalAmount,
  };

  Map<String, dynamic> toMap() => <String, dynamic>{
    'userId': userId,
    'items': items.map((key, value) => MapEntry(key, value.toMap())),
    'totalAmount': totalAmount,
  };
}

class CartItem {
  final String productId;
  final int? quantity;

  CartItem({required this.productId, this.quantity});

  CartItem.fromJson(Map<dynamic, dynamic> json)
    : productId = json['productId'] as String,
      quantity = json['quantity'] as int?;

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
    'productId': productId,
    if (quantity != null) 'quantity': quantity,
  };

  Map<String, dynamic> toMap() => <String, dynamic>{
    'productId': productId,
    if (quantity != null) 'quantity': quantity,
  };
}
