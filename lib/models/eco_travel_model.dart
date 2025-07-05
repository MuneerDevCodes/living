class EcoTravelSuggestion {
  final String key;
  final String title;
  final String description;
  final String category;
  final String location;
  final double carbonImpact;
  final String carbonUnit;
  final List<String> benefits;
  final List<String> tips;
  final String imageUrl;
  final bool isVerified;

  EcoTravelSuggestion({
    required this.key,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.carbonImpact,
    required this.carbonUnit,
    required this.benefits,
    required this.tips,
    required this.imageUrl,
    this.isVerified = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'carbonImpact': carbonImpact,
      'carbonUnit': carbonUnit,
      'benefits': benefits,
      'tips': tips,
      'imageUrl': imageUrl,
      'isVerified': isVerified,
    };
  }

  factory EcoTravelSuggestion.fromJson(String key, Map<String, dynamic> json) {
    return EcoTravelSuggestion(
      key: key,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      location: json['location'] ?? '',
      carbonImpact: (json['carbonImpact'] ?? 0).toDouble(),
      carbonUnit: json['carbonUnit'] ?? '',
      benefits: List<String>.from(json['benefits'] ?? []),
      tips: List<String>.from(json['tips'] ?? []),
      imageUrl: json['imageUrl'] ?? '',
      isVerified: json['isVerified'] ?? true,
    );
  }
} 