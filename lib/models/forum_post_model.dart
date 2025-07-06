class ForumPost {
  final String key;
  final String userId;
  final String title;
  final String content;
  final String author;
  final String authorId;
  final String authorName;
  final String category;
  final DateTime createdAt;
  final int likes;
  final List<ForumComment> comments;
  final String timestamp;

  ForumPost({
    required this.key,
    required this.userId,
    required this.title,
    required this.content,
    required this.author,
    required this.authorId,
    required this.authorName,
    required this.category,
    required this.createdAt,
    required this.likes,
    required this.comments,
    required this.timestamp,
  });

  ForumPost.fromJson(String key, Map<dynamic, dynamic> json)
      : key = key,
        userId = json['userId'] as String? ?? '',
        title = json['title'] as String? ?? '',
        content = json['content'] as String? ?? '',
        author = json['author'] as String? ?? '',
        authorId = json['authorId'] as String? ?? '',
        authorName = json['authorName'] as String? ?? '',
        category = json['category'] as String? ?? '',
        createdAt = DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
        likes = json['likes'] as int? ?? 0,
        comments = (json['comments'] as List<dynamic>? ?? []).map((comment) => ForumComment.fromJson(comment)).toList(),
        timestamp = json['timestamp'] as String? ?? DateTime.now().toIso8601String();

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'userId': userId,
        'title': title,
        'content': content,
        'author': author,
        'authorId': authorId,
        'authorName': authorName,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
        'likes': likes,
        'comments': comments.map((comment) => comment.toJson()).toList(),
        'timestamp': timestamp,
      };

  Map<String, dynamic> toMap() => <String, dynamic>{
        'userId': userId,
        'title': title,
        'content': content,
        'author': author,
        'authorId': authorId,
        'authorName': authorName,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
        'likes': likes,
        'comments': comments.map((comment) => comment.toJson()).toList(),
        'timestamp': timestamp,
      };
}

class ForumComment {
  final String author;
  final String content;
  final DateTime timestamp;

  ForumComment({
    required this.author,
    required this.content,
    required this.timestamp,
  });

  ForumComment.fromJson(Map<dynamic, dynamic> json)
      : author = json['author'] as String? ?? '',
        content = json['content'] as String? ?? '',
        timestamp = DateTime.parse(json['timestamp'] as String? ?? DateTime.now().toIso8601String());

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'author': author,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };
}