import 'package:firebase_database/firebase_database.dart';
import 'package:living/models/cart_model.dart';

class CartDAO {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref().child('cart');
  static final DatabaseReference _ordersDatabase = FirebaseDatabase.instance.ref().child('orders');

  // Get user's cart items
  static Future<List<CartItem>> getUserCart(String userId) async {
    try {
      final snapshot = await _database.orderByChild('userId').equalTo(userId).get();
      List<CartItem> cartItems = [];
      
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          cartItems.add(CartItem.fromJson(child.key!, child.value as Map<String, dynamic>));
        }
      }
      
      return cartItems;
    } catch (e) {
      throw Exception('Failed to fetch cart items: $e');
    }
  }

  // Add item to cart
  static Future<void> addToCart(CartItem item) async {
    try {
      await _database.push().set(item.toJson());
    } catch (e) {
      throw Exception('Failed to add item to cart: $e');
    }
  }

  // Update cart item quantity
  static Future<void> updateCartItem(CartItem item) async {
    try {
      await _database.child(item.key).update(item.toJson());
    } catch (e) {
      throw Exception('Failed to update cart item: $e');
    }
  }

  // Remove item from cart
  static Future<void> removeFromCart(String key) async {
    try {
      await _database.child(key).remove();
    } catch (e) {
      throw Exception('Failed to remove item from cart: $e');
    }
  }

  // Clear user's cart
  static Future<void> clearCart(String userId) async {
    try {
      final cartItems = await getUserCart(userId);
      for (var item in cartItems) {
        await _database.child(item.key).remove();
      }
    } catch (e) {
      throw Exception('Failed to clear cart: $e');
    }
  }

  // Get user's orders
  static Future<List<Order>> getUserOrders(String userId) async {
    try {
      final snapshot = await _ordersDatabase.orderByChild('userId').equalTo(userId).get();
      List<Order> orders = [];
      
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          orders.add(Order.fromJson(child.key!, child.value as Map<String, dynamic>));
        }
      }
      
      return orders;
    } catch (e) {
      throw Exception('Failed to fetch user orders: $e');
    }
  }

  // Place order
  static Future<void> placeOrder(Order order) async {
    try {
      await _ordersDatabase.push().set(order.toJson());
    } catch (e) {
      throw Exception('Failed to place order: $e');
    }
  }

  // Update order status (admin only)
  static Future<void> updateOrderStatus(String orderKey, String status) async {
    try {
      await _ordersDatabase.child(orderKey).update({'status': status});
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Get all orders (admin only)
  static Future<List<Order>> getAllOrders() async {
    try {
      final snapshot = await _ordersDatabase.get();
      List<Order> orders = [];
      
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          orders.add(Order.fromJson(child.key!, child.value as Map<String, dynamic>));
        }
      }
      
      return orders;
    } catch (e) {
      throw Exception('Failed to fetch all orders: $e');
    }
  }
} 