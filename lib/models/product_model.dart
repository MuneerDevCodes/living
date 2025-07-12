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

class Review {
  final String userId;
  final int rating;
  final String comment;
  final int likes;
  final int createdAt;

  Review({
    required this.userId,
    required this.rating,
    required this.comment,
    required this.likes,
    required this.createdAt,
  });

  factory Review.fromJson(Map<dynamic, dynamic> json) => Review(
        userId: json['userId'] as String,
        rating: json['rating'] as int,
        comment: json['comment'] as String,
        likes: json['likes'] as int? ?? 0,
        createdAt: json['createdAt'] as int,
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'rating': rating,
        'comment': comment,
        'likes': likes,
        'createdAt': createdAt,
      };
}

class Ratings {
  final double average;
  final int count;

  Ratings({required this.average, required this.count});

  factory Ratings.fromJson(Map<dynamic, dynamic> json) => Ratings(
        average: (json['average'] is int)
            ? (json['average'] as int).toDouble()
            : (json['average'] as double? ?? 0.0),
        count: json['count'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'average': average,
        'count': count,
      };
}

class Product {
  final String name;
  final Category category;
  final String description;
  final double ecoRating;
  final String imageUrl;
  final double price;
  final Ratings ratings;
  final Map<String, Review> reviews;

  Product({
    required this.name,
    required this.category,
    required this.description,
    required this.ecoRating,
    required this.imageUrl,
    required this.price,
    Ratings? ratings,
    Map<String, Review>? reviews,
  })  : ratings = ratings ?? Ratings(average: 0.0, count: 0),
        reviews = reviews ?? {};

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
            : (json['price'] as double? ?? 0.0),
        ratings = json['ratings'] != null
            ? Ratings.fromJson(json['ratings'] as Map<dynamic, dynamic>)
            : Ratings(average: 0.0, count: 0),
        reviews = json['reviews'] != null
            ? Map<String, Review>.from(
                (json['reviews'] as Map<dynamic, dynamic>).map(
                  (key, value) => MapEntry(
                    key as String,
                    Review.fromJson(value as Map<dynamic, dynamic>),
                  ),
                ),
              )
            : {};

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'name': name,
        'category': category.toJson(),
        'description': description,
        'ecoRating': ecoRating,
        'imageUrl': imageUrl,
        'price': price,
        'ratings': ratings.toJson(),
        'reviews': reviews.map((key, value) => MapEntry(key, value.toJson())),
      };

  Map<String, dynamic> toMap() => <String, dynamic>{
        'name': name,
        'category': category.toJson(),
        'description': description,
        'ecoRating': ecoRating,
        'imageUrl': imageUrl,
        'price': price,
        'ratings': ratings.toJson(),
        'reviews': reviews.map((key, value) => MapEntry(key, value.toJson())),
      };
}