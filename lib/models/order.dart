import 'package:living/models/enums.dart';

class Order {
  final String? id;
  final String userId;
  final Map<String, OrderItem> items;
  final double totalAmount;
  final double subtotal;
  final double shippingCost;
  final String shippingAddress;
  final String paymentMethod;
  final OrderStatus status;
  final int createdAt;
  final int? updatedAt;

  Order({
    this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.subtotal,
    required this.shippingCost,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  Order.fromJson(Map<dynamic, dynamic> json)
    : id = json['id'] as String?,
      userId = json['userId'] as String,
      items = (json['items'] as Map<dynamic, dynamic>).map(
        (key, value) => MapEntry(
          key.toString(),
          OrderItem.fromJson(value as Map<dynamic, dynamic>),
        ),
      ),
      totalAmount =
          (json['totalAmount'] is int)
              ? (json['totalAmount'] as int).toDouble()
              : (json['totalAmount'] as double),
      subtotal = json['subtotal'] != null
          ? ((json['subtotal'] is int)
              ? (json['subtotal'] as int).toDouble()
              : (json['subtotal'] as double))
          : 0.0,
      shippingCost = json['shippingCost'] != null
          ? ((json['shippingCost'] is int)
              ? (json['shippingCost'] as int).toDouble()
              : (json['shippingCost'] as double))
          : 0.0,
      shippingAddress = json['shippingAddress'] as String? ?? 'Default Address',
      paymentMethod = json['paymentMethod'] as String? ?? 'Default Payment',
      status = json['status'] != null
          ? OrderStatus.fromJson(json['status'] as String)
          : OrderStatus.pending,
      createdAt = json['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt = json['updatedAt'] as int?;

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
    'id': id,
    'userId': userId,
    'items': items.map((key, value) => MapEntry(key, value.toJson())),
    'totalAmount': totalAmount,
    'subtotal': subtotal,
    'shippingCost': shippingCost,
    'shippingAddress': shippingAddress,
    'paymentMethod': paymentMethod,
    'status': status.toJson(),
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'userId': userId,
    'items': items.map((key, value) => MapEntry(key, value.toMap())),
    'totalAmount': totalAmount,
    'subtotal': subtotal,
    'shippingCost': shippingCost,
    'shippingAddress': shippingAddress,
    'paymentMethod': paymentMethod,
    'status': status.toJson(),
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  Order copyWith({
    String? id,
    String? userId,
    Map<String, OrderItem>? items,
    double? totalAmount,
    double? subtotal,
    double? shippingCost,
    String? shippingAddress,
    String? paymentMethod,
    OrderStatus? status,
    int? createdAt,
    int? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      subtotal: subtotal ?? this.subtotal,
      shippingCost: shippingCost ?? this.shippingCost,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
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
