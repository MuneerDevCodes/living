class CartItem {
  final String key;
  final String userId;
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String imageUrl;
  final DateTime addedDate;

  CartItem({
    required this.key,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.addedDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'addedDate': addedDate.millisecondsSinceEpoch,
    };
  }

  factory CartItem.fromJson(String key, Map<String, dynamic> json) {
    return CartItem(
      key: key,
      userId: json['userId'] ?? '',
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      imageUrl: json['imageUrl'] ?? '',
      addedDate: DateTime.fromMillisecondsSinceEpoch(json['addedDate'] ?? 0),
    );
  }
}

class Order {
  final String key;
  final String userId;
  final List<CartItem> items;
  final double totalAmount;
  final String status;
  final DateTime orderDate;
  final String? shippingAddress;
  final String? paymentMethod;

  Order({
    required this.key,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
    this.shippingAddress,
    this.paymentMethod,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'orderDate': orderDate.millisecondsSinceEpoch,
      'shippingAddress': shippingAddress,
      'paymentMethod': paymentMethod,
    };
  }

  factory Order.fromJson(String key, Map<String, dynamic> json) {
    return Order(
      key: key,
      userId: json['userId'] ?? '',
      items: (json['items'] as List? ?? [])
          .map((item) => CartItem.fromJson('', item))
          .toList(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      orderDate: DateTime.fromMillisecondsSinceEpoch(json['orderDate'] ?? 0),
      shippingAddress: json['shippingAddress'],
      paymentMethod: json['paymentMethod'],
    );
  }
} 