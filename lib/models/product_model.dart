class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<dynamic, dynamic> json) =>
      Category(id: json['id'] as String, name: json['name'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Product {
  final String name;
  final Category category;
  final String description;
  final double ecoRating;
  final String imageUrl;
  final double price;

  Product({
    required this.name,
    required this.category,
    required this.description,
    required this.ecoRating,
    required this.imageUrl,
    required this.price,
  });

  Product.fromJson(Map<dynamic, dynamic> json)
      : name = json['name'] as String,
        category = json['category'] != null
            ? Category.fromJson(json['category'] as Map<dynamic, dynamic>)
            : Category(id: '', name: ''),
        description = json['description'] as String,
        ecoRating = (json['ecoRating'] is int)
            ? (json['ecoRating'] as int).toDouble()
            : (json['ecoRating'] as double? ?? 0.0),
        imageUrl = json['imageUrl'] as String,
        price = (json['price'] is int)
            ? (json['price'] as int).toDouble()
            : (json['price'] as double? ?? 0.0);

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'name': name,
        'category': category.toJson(),
        'description': description,
        'ecoRating': ecoRating,
        'imageUrl': imageUrl,
        'price': price,
      };

  Map<String, dynamic> toMap() => <String, dynamic>{
        'name': name,
        'category': category.toJson(),
        'description': description,
        'ecoRating': ecoRating,
        'imageUrl': imageUrl,
        'price': price,
      };
}