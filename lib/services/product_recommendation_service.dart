// ProductRecommendationService.dart
import '../models/product_model.dart';
import '../models/cart.dart';
import '../models/wish.dart';
import 'product_dao.dart';
import 'cart_dao.dart';
import 'wish_dao.dart';

class ProductRecommendationService {
  final ProductDao _productDao = ProductDao();
  final CartDao _cartDao = CartDao();
  final WishDao _wishDao = WishDao();

  /// Returns a list of recommended products for the given user.
  Future<List<Product>> getRecommendationsForUser(String userId) async {
    // Fetch all products
    final allProducts = await _fetchAllProducts();
    // Fetch user's cart and wishlist
    final cart = await _fetchUserCart(userId);
    final wishlist = await _fetchUserWishlist(userId);

    // Get product IDs in cart and wishlist
    final cartProductIds = cart?.items.keys.toSet() ?? <String>{};
    final wishProductIds = wishlist?.items.keys.toSet() ?? <String>{};
    final excludedProductIds = {...cartProductIds, ...wishProductIds};

    // Recommend products not in cart or wishlist (by productId)
    final recommendations = allProducts.where((p) => !excludedProductIds.contains(p.name)).toList(); // TODO: Use productId if available

    // Optionally: prioritize by ecoRating or category frequency (not implemented here)
    recommendations.sort((a, b) => b.ecoRating.compareTo(a.ecoRating));
    return recommendations;
  }

  Future<List<Product>> _fetchAllProducts() async {
    final snapshot = await _productDao.getProductList().get();
    List<Product> products = [];
    if (snapshot.exists) {
      for (var child in snapshot.children) {
        products.add(Product.fromJson(child.value as Map<dynamic, dynamic>));
      }
    }
    return products;
  }

  Future<Cart?> _fetchUserCart(String userId) async {
    final snapshot = await _cartDao.getCartList().orderByChild('userId').equalTo(userId).get();
    if (snapshot.exists && snapshot.children.isNotEmpty) {
      final cartMap = snapshot.children.first.value as Map<dynamic, dynamic>;
      return Cart.fromJson(cartMap);
    }
    return null;
  }

  Future<WishList?> _fetchUserWishlist(String userId) async {
    final snapshot = await _wishDao.getWishList().orderByChild('userId').equalTo(userId).get();
    if (snapshot.exists && snapshot.children.isNotEmpty) {
      final wishMap = snapshot.children.first.value as Map<dynamic, dynamic>;
      return WishList.fromJson(wishMap);
    }
    return null;
  }
} 