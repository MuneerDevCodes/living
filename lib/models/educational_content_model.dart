class EducationalContent {
  final String key;
  final String title;
  final String description;
  final String category;
  final String content;
  final String author;
  final DateTime publishDate;
  final List<String> tags;
  final String imageUrl;
  final String contentType; // article, video, infographic
  final String? videoUrl;
  final bool isPublished;

  EducationalContent({
    required this.key,
    required this.title,
    required this.description,
    required this.category,
    required this.content,
    required this.author,
    required this.publishDate,
    required this.tags,
    required this.imageUrl,
    required this.contentType,
    this.videoUrl,
    this.isPublished = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'content': content,
      'author': author,
      'publishDate': publishDate.millisecondsSinceEpoch,
      'tags': tags,
      'imageUrl': imageUrl,
      'contentType': contentType,
      'videoUrl': videoUrl,
      'isPublished': isPublished,
    };
  }

  factory EducationalContent.fromJson(String key, Map<String, dynamic> json) {
    return EducationalContent(
      key: key,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      content: json['content'] ?? '',
      author: json['author'] ?? '',
      publishDate: DateTime.fromMillisecondsSinceEpoch(json['publishDate'] ?? 0),
      tags: List<String>.from(json['tags'] ?? []),
      imageUrl: json['imageUrl'] ?? '',
      contentType: json['contentType'] ?? 'article',
      videoUrl: json['videoUrl'],
      isPublished: json['isPublished'] ?? true,
    );
  }
} 