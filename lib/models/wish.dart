class WishList {
  final String userId; // Added
  final Map<String, Wish> items;

  WishList({required this.userId, required this.items});

  WishList.fromJson(Map<dynamic, dynamic> json)
    : userId = json['userId'] as String, // Added
      items = (json['items'] as Map<dynamic, dynamic>).map(
        (key, value) => MapEntry(
          key.toString(),
          Wish.fromJson(value as Map<dynamic, dynamic>),
        ),
      );

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
    'userId': userId, // Added
    'items': items.map((key, value) => MapEntry(key, value.toJson())),
  };

  Map<String, dynamic> toMap() => <String, dynamic>{
    'userId': userId, // Added
    'items': items.map((key, value) => MapEntry(key, value.toMap())),
  };
}

class Wish {
  final String productId;

  Wish({required this.productId});

  Wish.fromJson(Map<dynamic, dynamic> json) : productId = json['productId'] as String;

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{'productId': productId};

  Map<String, dynamic> toMap() => <String, dynamic>{'productId': productId};
}
