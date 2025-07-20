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
  final String? uploadedBy;
  final DateTime? uploadedAt;
  final bool? approved;
  final bool? adminApproved;

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
    this.uploadedBy,
    this.uploadedAt,
    this.approved,
    this.adminApproved,
  });

  factory GalleryItem.fromJson(Map<String, dynamic> json) {
    // Handle webImageBytes separately since it might not be stored in SharedPreferences
    Uint8List? webBytes;
    if (json['webImageBytes'] != null) {
      try {
        webBytes = Uint8List.fromList(List<int>.from(json['webImageBytes']));
      } catch (e) {
        // If webImageBytes can't be parsed, set it to null
        webBytes = null;
      }
    }

    // Parse uploadedAt date
    DateTime? uploadedAt;
    if (json['uploadedAt'] != null) {
      try {
        uploadedAt = DateTime.parse(json['uploadedAt']);
      } catch (e) {
        uploadedAt = null;
      }
    }

    return GalleryItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? '',
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      isLocal: json['isLocal'] ?? false,
      isWebMemory: json['isWebMemory'] ?? false,
      webImageBytes: webBytes,
      uploadedBy: json['uploadedBy'],
      uploadedAt: uploadedAt,
      approved: json['approved'],
      adminApproved: json['adminApproved'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'likes': likes,
      'comments': comments,
      'isLocal': isLocal,
      'isWebMemory': isWebMemory,
      'uploadedBy': uploadedBy,
      'uploadedAt': uploadedAt?.toIso8601String(),
      'approved': approved,
      'adminApproved': adminApproved,
    };

    // Only include webImageBytes if it's not null and not too large
    if (webImageBytes != null && webImageBytes!.length < 1000000) { // 1MB limit
      data['webImageBytes'] = webImageBytes!.toList();
    }

    return data;
  }

  // Create a copy of the item with updated properties
  GalleryItem copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? category,
    int? likes,
    int? comments,
    bool? isLocal,
    bool? isWebMemory,
    Uint8List? webImageBytes,
    String? uploadedBy,
    DateTime? uploadedAt,
    bool? approved,
    bool? adminApproved,
  }) {
    return GalleryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      isLocal: isLocal ?? this.isLocal,
      isWebMemory: isWebMemory ?? this.isWebMemory,
      webImageBytes: webImageBytes ?? this.webImageBytes,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      approved: approved ?? this.approved,
      adminApproved: adminApproved ?? this.adminApproved,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GalleryItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GalleryItem(id: $id, title: $title, category: $category, likes: $likes)';
  }
} 