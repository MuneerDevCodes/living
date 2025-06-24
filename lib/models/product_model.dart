class Product {
  final String name;
  final String category;
  final String description;
  final double ecoRating;
  final String imageUrl;
  final List<String> tags;

  Product({
    required this.name,
    required this.category,
    required this.description,
    required this.ecoRating,
    required this.imageUrl,
    required this.tags,
  });

  Product.fromJson(Map<dynamic, dynamic> json)
      : name = json['name'] as String,
        category = json['category'] as String,
        description = json['description'] as String,
        ecoRating = json['ecoRating'] as double,
        imageUrl = json['imageUrl'] as String,
        tags = List<String>.from(json['tags'] as List);

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'name': name,
        'category': category,
        'description': description,
        'ecoRating': ecoRating,
        'imageUrl': imageUrl,
        'tags': tags,
      };

  Map<String, dynamic> toMap() => <String, dynamic>{
        'name': name,
        'category': category,
        'description': description,
        'ecoRating': ecoRating,
        'imageUrl': imageUrl,
        'tags': tags,
      };
}