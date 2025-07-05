class EnergyTip {
  final String key;
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final double potentialSavings;
  final String savingsUnit;
  final List<String> steps;
  final String imageUrl;
  final bool isVerified;

  EnergyTip({
    required this.key,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.potentialSavings,
    required this.savingsUnit,
    required this.steps,
    required this.imageUrl,
    this.isVerified = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'potentialSavings': potentialSavings,
      'savingsUnit': savingsUnit,
      'steps': steps,
      'imageUrl': imageUrl,
      'isVerified': isVerified,
    };
  }

  factory EnergyTip.fromJson(String key, Map<String, dynamic> json) {
    return EnergyTip(
      key: key,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      difficulty: json['difficulty'] ?? 'Easy',
      potentialSavings: (json['potentialSavings'] ?? 0).toDouble(),
      savingsUnit: json['savingsUnit'] ?? '',
      steps: List<String>.from(json['steps'] ?? []),
      imageUrl: json['imageUrl'] ?? '',
      isVerified: json['isVerified'] ?? true,
    );
  }
} 