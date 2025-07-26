class Recipe {
  final String title;
  final List<String> ingredients;
  final String steps;
  final double carbonScore;
  final String? imageUrl; // Optional image URL

  Recipe({
    required this.title,
    required this.ingredients,
    required this.steps,
    required this.carbonScore,
    this.imageUrl,
  });

  Recipe.fromJson(Map<dynamic, dynamic> json)
      : title = json['title'] as String,
        ingredients = List<String>.from(json['ingredients'] as List),
        steps = json['steps'] as String,
        carbonScore = json['carbonScore'] as double,
        imageUrl = json['imageUrl'] as String?;

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'title': title,
        'ingredients': ingredients,
        'steps': steps,
        'carbonScore': carbonScore,
        'imageUrl': imageUrl,
      };

  Map<String, dynamic> toMap() => <String, dynamic>{
        'title': title,
        'ingredients': ingredients,
        'steps': steps,
        'carbonScore': carbonScore,
        'imageUrl': imageUrl,
      };
}