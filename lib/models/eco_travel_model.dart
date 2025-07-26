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
  final String createdBy; // User ID who created the suggestion
  final String createdByName; // Display name of the creator
  final DateTime createdAt; // When the suggestion was created
  final DateTime? verifiedAt; // When it was verified (if verified)
  final String? verifiedBy; // Admin who verified it (if verified)
  final String status; // 'pending', 'approved', 'rejected'

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
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.isVerified = false,
    this.verifiedAt,
    this.verifiedBy,
    this.status = 'pending',
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
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'verifiedAt': verifiedAt?.millisecondsSinceEpoch,
      'verifiedBy': verifiedBy,
      'status': status,
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
      isVerified: json['isVerified'] ?? false,
      createdBy: json['createdBy'] ?? '',
      createdByName: json['createdByName'] ?? 'Unknown User',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
      verifiedAt: json['verifiedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(json['verifiedAt']) : null,
      verifiedBy: json['verifiedBy'],
      status: json['status'] ?? 'pending',
    );
  }

  // Create a copy with updated verification status
  EcoTravelSuggestion copyWith({
    String? key,
    String? title,
    String? description,
    String? category,
    String? location,
    double? carbonImpact,
    String? carbonUnit,
    List<String>? benefits,
    List<String>? tips,
    String? imageUrl,
    bool? isVerified,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    DateTime? verifiedAt,
    String? verifiedBy,
    String? status,
  }) {
    return EcoTravelSuggestion(
      key: key ?? this.key,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      carbonImpact: carbonImpact ?? this.carbonImpact,
      carbonUnit: carbonUnit ?? this.carbonUnit,
      benefits: benefits ?? this.benefits,
      tips: tips ?? this.tips,
      imageUrl: imageUrl ?? this.imageUrl,
      isVerified: isVerified ?? this.isVerified,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      status: status ?? this.status,
    );
  }
} 