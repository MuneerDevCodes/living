import 'package:firebase_database/firebase_database.dart';
import 'package:living/models/product_model.dart';

class ProductDao {
  final _databaseRef = FirebaseDatabase.instance.ref("products");

  void saveProduct(Product product) {
    _databaseRef.push().set(product.toJson());
  }

  Query getProductList() {
    return _databaseRef;
  }

  void deleteProduct(String key) {
    _databaseRef.child(key).remove();
  }

  void updateProduct(String key, Product product) {
    _databaseRef.child(key).update(product.toMap());
  }

  Future<Product?> getProductById(String productId) async {
    final snapshot = await _databaseRef.child(productId).get();
    if (snapshot.exists) {
      return Product.fromJson(snapshot.value as Map<dynamic, dynamic>);
    }
    return null;
  }
}
