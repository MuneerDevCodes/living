import 'dart:typed_data';

class GalleryItem {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String category;
  final int likes;
  final int comments;
  final bool isLocal;
  final bool isWebMemory;
  final Uint8List? webImageBytes;

  GalleryItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.likes,
    required this.comments,
    this.isLocal = false,
    this.isWebMemory = false,
    this.webImageBytes,
  });

  factory GalleryItem.fromJson(Map<String, dynamic> json) => GalleryItem(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        imageUrl: json['imageUrl'],
        category: json['category'],
        likes: json['likes'],
        comments: json['comments'],
        isLocal: json['isLocal'] ?? false,
        isWebMemory: json['isWebMemory'] ?? false,
        webImageBytes: json['webImageBytes'] != null
            ? Uint8List.fromList(List<int>.from(json['webImageBytes']))
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'category': category,
        'likes': likes,
        'comments': comments,
        'isLocal': isLocal,
        'isWebMemory': isWebMemory,
        'webImageBytes': webImageBytes?.toList(),
      };
} 