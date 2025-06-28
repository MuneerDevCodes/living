import 'package:firebase_database/firebase_database.dart';
import '../models/product_model.dart';

class CategoryDao {
  final DatabaseReference _categoryRef = FirebaseDatabase.instance.ref(
    'categories',
  );

  DatabaseReference getCategoryRef() => _categoryRef;

  Stream<DatabaseEvent> getCategoryListStream() => _categoryRef.onValue;

  Future<List<Category>> getAllCategories() async {
    final snap = await _categoryRef.get();
    final data = snap.value;
    if (data == null) return [];
    final map = Map<String, dynamic>.from(data as dynamic);
    return map.values
        .map((v) => Category.fromJson(Map<String, dynamic>.from(v)))
        .toList();
  }

  Future<void> addCategory(Category category) async {
    final ref = _categoryRef.push();
    await ref.set(category.toJson());
  }

  Future<void> updateCategory(Category category) async {
    await _categoryRef.child(category.id).set(category.toJson());
  }

  Future<void> deleteCategory(String id) async {
    await _categoryRef.child(id).remove();
  }
}
