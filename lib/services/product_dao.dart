import 'package:firebase_database/firebase_database.dart';
import 'package:living/models/product_model.dart';

class ProductDao {
  final _databaseRef = FirebaseDatabase.instance.ref("products");

  Future<void> saveProduct(Product product) async {
    try {
      print('Attempting to save product: ${product.name}');
      print('Database URL: ${FirebaseDatabase.instance.databaseURL}');
      final result = await _databaseRef.push().set(product.toJson());
      print('Product saved successfully');
    } catch (e) {
      print('Error saving product: $e');
      rethrow;
    }
  }

  Query getProductList() {
    return _databaseRef;
  }

  Future<void> deleteProduct(String key) async {
    try {
      print('Deleting product with key: $key');
      await _databaseRef.child(key).remove();
      print('Product deleted successfully');
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }

  Future<void> updateProduct(String key, Product product) async {
    try {
      print('Updating product: ${product.name}');
      await _databaseRef.child(key).update(product.toMap());
      print('Product updated successfully');
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }

  Future<Product?> getProductById(String productId) async {
    final snapshot = await _databaseRef.child(productId).get();
    if (snapshot.exists) {
      return Product.fromJson(snapshot.value as Map<dynamic, dynamic>);
    }
    return null;
  }

  Future<void> testConnection() async {
    try {
      print('Testing Firebase connection...');
      print('Database URL: ${FirebaseDatabase.instance.databaseURL}');
      print('App name: ${FirebaseDatabase.instance.app.name}');
      
      // Test reading from categories first
      final categoriesRef = FirebaseDatabase.instance.ref("categories");
      final categoriesSnapshot = await categoriesRef.limitToFirst(1).get();
      print('Categories test successful. Found ${categoriesSnapshot.children.length} categories');
      
      // Test reading from products
      final snapshot = await _databaseRef.limitToFirst(1).get();
      print('Products test successful. Found ${snapshot.children.length} products');
    } catch (e) {
      print('Connection test failed: $e');
      rethrow;
    }
  }
}
