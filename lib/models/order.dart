import 'package:living/models/enums.dart';

class Order {
  final String userId;
  final Map<String, OrderItem> items;
  final double totalAmount;

  Order({required this.userId, required this.items, required this.totalAmount});

  Order.fromJson(Map<dynamic, dynamic> json)
    : userId = json['userId'] as String,
      items = (json['items'] as Map<dynamic, dynamic>).map(
        (key, value) => MapEntry(
          key.toString(),
          OrderItem.fromJson(value as Map<dynamic, dynamic>),
        ),
      ),
      totalAmount =
          (json['totalAmount'] is int)
              ? (json['totalAmount'] as int).toDouble()
              : (json['totalAmount'] as double);

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

class OrderItem {
  final String productId;
  final int quantity;
  final double price;
  final OrderStatus status;

  OrderItem({
    required this.productId,
    required this.quantity,
    required this.price,
    required this.status,
  });

  OrderItem.fromJson(Map<dynamic, dynamic> json)
    : productId = json['productId'] as String,
      quantity = json['quantity'] as int,
      price =
          (json['price'] is int)
              ? (json['price'] as int).toDouble()
              : (json['price'] as double),
      status =
          json['status'] != null
              ? OrderStatus.fromJson(json['status'] as String)
              : OrderStatus.pending;

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
    'productId': productId,
    'quantity': quantity,
    'price': price,
    'status': status.toJson(),
  };

  Map<String, dynamic> toMap() => <String, dynamic>{
    'productId': productId,
    'quantity': quantity,
    'price': price,
    'status': status.toJson(),
  };
}
