class Recipe {
  final String title;
  final List<String> ingredients;
  final String steps;
  final double carbonScore;

  Recipe({
    required this.title,
    required this.ingredients,
    required this.steps,
    required this.carbonScore,
  });

  Recipe.fromJson(Map<dynamic, dynamic> json)
      : title = json['title'] as String,
        ingredients = List<String>.from(json['ingredients'] as List),
        steps = json['steps'] as String,
        carbonScore = json['carbonScore'] as double;

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'title': title,
        'ingredients': ingredients,
        'steps': steps,
        'carbonScore': carbonScore,
      };

  Map<String, dynamic> toMap() => <String, dynamic>{
        'title': title,
        'ingredients': ingredients,
        'steps': steps,
        'carbonScore': carbonScore,
      };
}