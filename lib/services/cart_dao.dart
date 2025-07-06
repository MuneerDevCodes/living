import 'package:firebase_database/firebase_database.dart';
import 'package:living/models/cart.dart';
import 'package:living/models/product_model.dart';

class CartDao {
  final _databaseRef = FirebaseDatabase.instance.ref("carts");

  void saveCart(Cart cart) {
    _databaseRef.push().set(cart.toJson());
  }

  Query getCartList() {
    return _databaseRef;
  }

  void deleteCart(String key) {
    _databaseRef.child(key).remove();
  }

  void updateCart(String key, Cart cart) {
    _databaseRef.child(key).update(cart.toMap());
  }

  Future<void> addToCart(
    String userId,
    Product product,
    int quantity,
    String productId,
  ) async {
    final snapshot =
        await _databaseRef.orderByChild('userId').equalTo(userId).get();
    if (snapshot.exists && snapshot.children.isNotEmpty) {
      final cartSnap = snapshot.children.first;
      final cartMap = cartSnap.value as Map<dynamic, dynamic>;
      final cart = Cart.fromJson(cartMap);
      final items = Map<String, CartItem>.from(cart.items);
      // If item exists, increment quantity, else add new
      if (items.containsKey(productId)) {
        final oldItem = items[productId]!;
        final newQty = (oldItem.quantity ?? 1) + quantity;
        items[productId] = CartItem(productId: productId, quantity: newQty);
      } else {
        items[productId] = CartItem(productId: productId, quantity: quantity);
      }
      // Recalculate total
      double total = 0.0;
      items.forEach((k, v) {
        // You may want to fetch product price from DB, here we use passed product.price for simplicity
        total += (v.quantity ?? 1) * product.price;
      });
      final updatedCart = Cart(
        userId: userId,
        items: items,
        totalAmount: total,
      );
      await _databaseRef.child(cartSnap.key!).set(updatedCart.toJson());
    } else {
      final items = <String, CartItem>{
        productId: CartItem(productId: productId, quantity: quantity),
      };
      final cart = Cart(
        userId: userId,
        items: items,
        totalAmount: product.price * quantity,
      );
      await _databaseRef.push().set(cart.toJson());
    }
  }

  Future<void> removeFromCart(String userId, String productId) async {
    final snapshot =
        await _databaseRef.orderByChild('userId').equalTo(userId).get();
    if (snapshot.exists && snapshot.children.isNotEmpty) {
      final cartSnap = snapshot.children.first;
      final cartMap = cartSnap.value as Map<dynamic, dynamic>;
      final cart = Cart.fromJson(cartMap);
      final items = Map<String, CartItem>.from(cart.items);
      if (items.containsKey(productId)) {
        final oldItem = items[productId]!;
        final newQty = (oldItem.quantity ?? 1) - 1;
        if (newQty > 0) {
          items[productId] = CartItem(productId: productId, quantity: newQty);
        } else {
          items.remove(productId);
        }
        // Recalculate total
        double total = 0.0;
        items.forEach((k, v) {
          // You may want to fetch product price from DB, here we use 0 for removed
          total += (v.quantity ?? 1) * 0;
        });
        final updatedCart = Cart(
          userId: userId,
          items: items,
          totalAmount: total,
        );
        await _databaseRef.child(cartSnap.key!).set(updatedCart.toJson());
      }
    }
  }

  Future<void> clearCart(String userId) async {
    final snapshot =
        await _databaseRef.orderByChild('userId').equalTo(userId).get();
    if (snapshot.exists && snapshot.children.isNotEmpty) {
      final cartSnap = snapshot.children.first;
      await _databaseRef.child(cartSnap.key!).remove();
    }
  }
}
