import 'package:firebase_database/firebase_database.dart';
import '../models/recipe_model.dart';

class RecipeDao {
  final _databaseRef = FirebaseDatabase.instance.ref("recipes");

  void saveRecipe(Recipe recipe) {
    _databaseRef.push().set(recipe.toJson());
  }

  Query getRecipeList() {
    return _databaseRef;
  }

  void deleteRecipe(String key) {
    _databaseRef.child(key).remove();
  }

  void updateRecipe(String key, Recipe recipe) {
    _databaseRef.child(key).update(recipe.toMap());
  }

  Future<Recipe?> getRecipeById(String recipeId) async {
    final snapshot = await _databaseRef.child(recipeId).get();
    if (snapshot.exists) {
      return Recipe.fromJson(snapshot.value as Map<dynamic, dynamic>);
    }
    return null;
  }
}
