import 'user_model.dart';
import 'product_model.dart';
import 'recipe_model.dart';
import 'forum_post_model.dart';

class AppData {
  final Map<String, User> users;
  final Map<String, Product> products;
  final Map<String, Recipe> recipes;
  final Map<String, ForumPost> forumPosts;

  AppData({
    required this.users,
    required this.products,
    required this.recipes,
    required this.forumPosts,
  });

  AppData.fromJson(Map<dynamic, dynamic> json)
      : users = (json['users'] as Map<dynamic, dynamic>).map(
          (key, value) => MapEntry(
            key.toString(),
            User.fromJson(value as Map<dynamic, dynamic>),
          ),
        ),
        products = (json['products'] as Map<dynamic, dynamic>).map(
          (key, value) => MapEntry(
            key.toString(),
            Product.fromJson(value as Map<dynamic, dynamic>),
          ),
        ),
        recipes = (json['recipes'] as Map<dynamic, dynamic>).map(
          (key, value) => MapEntry(
            key.toString(),
            Recipe.fromJson(value as Map<dynamic, dynamic>),
          ),
        ),
        forumPosts = (json['forumPosts'] as Map<dynamic, dynamic>).map(
          (key, value) => MapEntry(
            key.toString(),
            ForumPost.fromJson(key.toString(), value as Map<dynamic, dynamic>),
          ),
        );

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'users': users.map((key, value) => MapEntry(key, value.toJson())),
        'products': products.map((key, value) => MapEntry(key, value.toJson())),
        'recipes': recipes.map((key, value) => MapEntry(key, value.toJson())),
        'forumPosts': forumPosts.map((key, value) => MapEntry(key, value.toJson())),
      };

  Map<String, dynamic> toMap() => <String, dynamic>{
        'users': users.map((key, value) => MapEntry(key, value.toMap())),
        'products': products.map((key, value) => MapEntry(key, value.toMap())),
        'recipes': recipes.map((key, value) => MapEntry(key, value.toMap())),
        'forumPosts': forumPosts.map((key, value) => MapEntry(key, value.toMap())),
      };
}