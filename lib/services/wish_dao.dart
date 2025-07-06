import 'package:firebase_database/firebase_database.dart';
import 'package:living/models/wish.dart';
import 'package:living/models/product_model.dart';

class WishDao {
  final _databaseRef = FirebaseDatabase.instance.ref("wishlists");

  void saveWishList(WishList wishList) {
    _databaseRef.push().set(wishList.toJson());
  }

  Query getWishList() {
    return _databaseRef;
  }

  void deleteWishList(String key) {
    _databaseRef.child(key).remove();
  }

  void updateWishList(String key, WishList wishList) {
    _databaseRef.child(key).update(wishList.toMap());
  }

  Future<void> addToWishList(String userId, Product product, String productId) async {
    // Find wishlist for user
    final snapshot =
        await _databaseRef.orderByChild('userId').equalTo(userId).get();
    if (snapshot.exists && snapshot.children.isNotEmpty) {
      final wishSnap = snapshot.children.first;
      final wishMap = wishSnap.value as Map<dynamic, dynamic>;
      final wishList = WishList.fromJson(wishMap);
      final items = Map<String, Wish>.from(wishList.items);
      if (!items.containsKey(productId)) {
        items[productId] = Wish(productId: productId);
        final updatedWishList = WishList(userId: userId, items: items);
        await _databaseRef.child(wishSnap.key!).set(updatedWishList.toJson());
      }
    } else {
      // Create new wishlist
      final items = <String, Wish>{productId: Wish(productId: productId)};
      final wishList = WishList(userId: userId, items: items);
      await _databaseRef.push().set(wishList.toJson());
    }
  }

  Future<void> removeFromWishList(String userId, String productId) async {
    // Find wishlist for user
    final snapshot =
        await _databaseRef.orderByChild('userId').equalTo(userId).get();
    if (snapshot.exists && snapshot.children.isNotEmpty) {
      final wishSnap = snapshot.children.first;
      final wishMap = wishSnap.value as Map<dynamic, dynamic>;
      final wishList = WishList.fromJson(wishMap);
      final items = Map<String, Wish>.from(wishList.items);
      if (items.containsKey(productId)) {
        items.remove(productId);
        final updatedWishList = WishList(userId: userId, items: items);
        await _databaseRef.child(wishSnap.key!).set(updatedWishList.toJson());
      }
    }
  }
}
