import 'package:living/models/enums.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:living/models/order.dart';
import 'package:living/models/cart.dart';
import 'package:living/services/product_dao.dart';

class OrderDao {
  final _databaseRef = FirebaseDatabase.instance.ref("orders");

  void saveOrder(Order order) {
    final orderRef = _databaseRef.push();
    final orderWithId = Order(
      id: orderRef.key,
      userId: order.userId,
      items: order.items,
      subtotal: order.subtotal,
      shippingCost: order.shippingCost,
      totalAmount: order.totalAmount,
      shippingAddress: order.shippingAddress,
      paymentMethod: order.paymentMethod,
      status: order.status,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
    );
    orderRef.set(orderWithId.toJson());
  }

  Query getOrderList() {
    return _databaseRef;
  }

  void deleteOrder(String key) {
    _databaseRef.child(key).remove();
  }

  void updateOrder(String key, Order order) {
    final updatedOrder = Order(
      id: key,
      userId: order.userId,
      items: order.items,
      subtotal: order.subtotal,
      shippingCost: order.shippingCost,
      totalAmount: order.totalAmount,
      shippingAddress: order.shippingAddress,
      paymentMethod: order.paymentMethod,
      status: order.status,
      createdAt: order.createdAt,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    _databaseRef.child(key).update(updatedOrder.toMap());
  }

  Future<void> createOrderFromCart(
    String userId, 
    Cart cart, 
    String shippingAddress, 
    String paymentMethod,
    double shippingCost,
  ) async {
    final items = <String, OrderItem>{};
    final productDao = ProductDao();
    double subtotal = 0.0;
    
    for (final entry in cart.items.entries) {
      final cartItem = entry.value;
      final product = await productDao.getProductById(cartItem.productId);
      final price = product?.price ?? 0.0;
      final itemTotal = price * (cartItem.quantity ?? 1);
      subtotal += itemTotal;
      
      items[entry.key] = OrderItem(
        productId: cartItem.productId,
        quantity: cartItem.quantity ?? 1,
        price: price,
        status: OrderStatus.pending,
      );
    }
    
    final totalAmount = subtotal + shippingCost;
    
    final order = Order(
      userId: userId,
      items: items,
      subtotal: subtotal,
      shippingCost: shippingCost,
      totalAmount: totalAmount,
      shippingAddress: shippingAddress,
      paymentMethod: paymentMethod,
      status: OrderStatus.pending,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    
    saveOrder(order);
    
    // Clear cart after successful order
    final cartRef = FirebaseDatabase.instance.ref("carts");
    final snapshot = await cartRef.orderByChild('userId').equalTo(userId).get();
    if (snapshot.exists && snapshot.children.isNotEmpty) {
      final cartSnap = snapshot.children.first;
      await cartRef.child(cartSnap.key!).remove();
    }
  }

  Future<Order?> getOrderById(String orderId) async {
    final snapshot = await _databaseRef.child(orderId).get();
    if (snapshot.exists && snapshot.value != null) {
      return Order.fromJson(Map<dynamic, dynamic>.from(snapshot.value as Map));
    }
    return null;
  }

  Query getOrdersByUserId(String userId) {
    return _databaseRef.orderByChild('userId').equalTo(userId);
  }
}
