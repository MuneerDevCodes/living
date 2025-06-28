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

class Book {
  final String title;
  final String author;
  final Category category;
  final String description;
  final String coverImageURL;
  final double price;
  final bool isBestseller;
  final bool isNewArrival;
  final Ratings ratings;
  final Map<String, Review> reviews;

  Book({
    required this.title,
    required this.author,
    required this.category,
    required this.description,
    required this.coverImageURL,
    required this.price,
    required this.isBestseller,
    required this.isNewArrival,
    required this.ratings,
    required this.reviews,
  });

  Book.fromJson(Map<dynamic, dynamic> json)
    : title = json['title'] as String,
      author = json['author'] as String,
      category =
          json['category'] != null
              ? Category.fromJson(json['category'] as Map<dynamic, dynamic>)
              : Category(id: '', name: ''),
      description = json['description'] as String,
      coverImageURL = json['coverImageURL'] as String,
      price =
          (json['price'] is int)
              ? (json['price'] as int).toDouble()
              : (json['price'] as double? ?? 0.0),
      isBestseller =
          json['isBestseller'] is bool
              ? json['isBestseller'] as bool
              : (json['isBestseller'] == 1),
      isNewArrival =
          json['isNewArrival'] is bool
              ? json['isNewArrival'] as bool
              : (json['isNewArrival'] == 1),
      ratings =
          json['ratings'] != null
              ? Ratings.fromJson(json['ratings'] as Map<dynamic, dynamic>)
              : Ratings(average: 0, count: 0),
      reviews =
          (json['reviews'] as Map<dynamic, dynamic>?)?.map(
            (key, value) => MapEntry(
              key.toString(),
              Review.fromJson(value as Map<dynamic, dynamic>),
            ),
          ) ??
          {};

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
    'title': title,
    'author': author,
    'category': category.toJson(),
    'description': description,
    'coverImageURL': coverImageURL,
    'price': price,
    'isBestseller': isBestseller,
    'isNewArrival': isNewArrival,
    'ratings': ratings.toJson(),
    'reviews': reviews.map((key, value) => MapEntry(key, value.toJson())),
  };

  Map<String, dynamic> toMap() => <String, dynamic>{
    'title': title,
    'author': author,
    'category': category.toJson(),
    'description': description,
    'coverImageURL': coverImageURL,
    'price': price,
    'isBestseller': isBestseller,
    'isNewArrival': isNewArrival,
    'ratings': ratings.toMap(),
    'reviews': reviews.map((key, value) => MapEntry(key, value.toMap())),
  };
}

class Ratings {
  final double average;
  final int count;

  Ratings({required this.average, required this.count});

  Ratings.fromJson(Map<dynamic, dynamic>? json)
    : average =
          (json?['average'] is int)
              ? (json?['average'] as int).toDouble()
              : (json?['average'] as double? ?? 0.0),
      count = json?['count'] as int? ?? 0;

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
    'average': average,
    'count': count,
  };

  Map<String, dynamic> toMap() => <String, dynamic>{
    'average': average,
    'count': count,
  };
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

  Review.fromJson(Map<dynamic, dynamic> json)
    : userId = json['userId'] as String? ?? '',
      rating = json['rating'] as int? ?? 0,
      comment = json['comment'] as String? ?? '',
      likes = json['likes'] as int? ?? 0,
      createdAt = json['createdAt'] as int? ?? 0;

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
    'userId': userId,
    'rating': rating,
    'comment': comment,
    'likes': likes,
    'createdAt': createdAt,
  };

  Map<String, dynamic> toMap() => <String, dynamic>{
    'userId': userId,
    'rating': rating,
    'comment': comment,
    'likes': likes,
    'createdAt': createdAt,
  };
}
