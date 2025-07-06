import 'package:living/models/enums.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:living/models/order.dart';
import 'package:living/models/cart.dart';
import 'package:living/services/product_dao.dart';

class OrderDao {
  final _databaseRef = FirebaseDatabase.instance.ref("orders");

  void saveOrder(Order order) {
    _databaseRef.push().set(order.toJson());
  }

  Query getOrderList() {
    return _databaseRef;
  }

  void deleteOrder(String key) {
    _databaseRef.child(key).remove();
  }

  void updateOrder(String key, Order order) {
    _databaseRef.child(key).update(order.toMap());
  }

  Future<void> createOrderFromCart(String userId, Cart cart) async {
    final items = <String, OrderItem>{};
    final productDao = ProductDao();
    for (final entry in cart.items.entries) {
      final cartItem = entry.value;
      final product = await productDao.getProductById(cartItem.productId);
      final price = product?.price ?? 0.0;
      items[entry.key] = OrderItem(
        productId: cartItem.productId,
        quantity: cartItem.quantity ?? 1,
        price: price,
        status: OrderStatus.pending,
      );
    }
    final order = Order(
      userId: userId,
      items: items,
      totalAmount: cart.totalAmount,
    );
    await _databaseRef.push().set(order.toJson());
    // Optionally clear cart after order
    final cartRef = FirebaseDatabase.instance.ref("carts");
    final snapshot = await cartRef.orderByChild('userId').equalTo(userId).get();
    if (snapshot.exists && snapshot.children.isNotEmpty) {
      final cartSnap = snapshot.children.first;
      await cartRef.child(cartSnap.key!).remove();
    }
  }
}
