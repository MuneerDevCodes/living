class ForumPost {
  final String key;
  final String userId;
  final String title;
  final String content;
  final String author;
  final String authorId;
  final String authorName;
  final String? authorProfileImageUrl;
  final String category;
  final DateTime createdAt;
  final DateTime? lastEdited;
  final int likes;
  final List<String> tags;
  final String status; // 'open', 'closed'
  final List<String> attachmentUrls;
  final String? postImageUrl;
  final String timestamp;

  ForumPost({
    required this.key,
    required this.userId,
    required this.title,
    required this.content,
    required this.author,
    required this.authorId,
    required this.authorName,
    this.authorProfileImageUrl,
    required this.category,
    required this.createdAt,
    this.lastEdited,
    required this.likes,
    this.tags = const [],
    this.status = 'open',
    this.attachmentUrls = const [],
    this.postImageUrl,
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
        authorProfileImageUrl = json['authorProfileImageUrl'] as String?,
        category = json['category'] as String? ?? '',
        createdAt = DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
        lastEdited = json['lastEdited'] != null ? DateTime.parse(json['lastEdited']) : null,
        likes = json['likes'] as int? ?? 0,
        tags = List<String>.from(json['tags'] ?? []),
        status = json['status'] as String? ?? 'open',
        attachmentUrls = List<String>.from(json['attachmentUrls'] ?? []),
        postImageUrl = json['postImageUrl'] as String?,
        timestamp = json['timestamp'] as String? ?? DateTime.now().toIso8601String();

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'userId': userId,
        'title': title,
        'content': content,
        'author': author,
        'authorId': authorId,
        'authorName': authorName,
        'authorProfileImageUrl': authorProfileImageUrl,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
        'lastEdited': lastEdited?.toIso8601String(),
        'likes': likes,
        'tags': tags,
        'status': status,
        'attachmentUrls': attachmentUrls,
        'postImageUrl': postImageUrl,
        'timestamp': timestamp,
      };

  Map<String, dynamic> toMap() => <String, dynamic>{
        'userId': userId,
        'title': title,
        'content': content,
        'author': author,
        'authorId': authorId,
        'authorName': authorName,
        'authorProfileImageUrl': authorProfileImageUrl,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
        'lastEdited': lastEdited?.toIso8601String(),
        'likes': likes,
        'tags': tags,
        'status': status,
        'attachmentUrls': attachmentUrls,
        'postImageUrl': postImageUrl,
        'timestamp': timestamp,
      };
}

class ForumComment {
  final String key;
  final String postId;
  final String author;
  final String authorId;
  final String? authorProfileImageUrl;
  final String content;
  final DateTime createdAt;
  final DateTime? lastEdited;
  final List<String> attachmentUrls;

  ForumComment({
    required this.key,
    required this.postId,
    required this.author,
    required this.authorId,
    this.authorProfileImageUrl,
    required this.content,
    required this.createdAt,
    this.lastEdited,
    this.attachmentUrls = const [],
  });

  ForumComment.fromJson(Map<dynamic, dynamic> json)
      : key = json['key'] as String? ?? '',
        postId = json['postId'] as String? ?? '',
        author = json['author'] as String? ?? '',
        authorId = json['authorId'] as String? ?? '',
        authorProfileImageUrl = json['authorProfileImageUrl'] as String?,
        content = json['content'] as String? ?? '',
        createdAt = DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
        lastEdited = json['lastEdited'] != null ? DateTime.parse(json['lastEdited']) : null,
        attachmentUrls = List<String>.from(json['attachmentUrls'] ?? []);

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'key': key,
        'postId': postId,
        'author': author,
        'authorId': authorId,
        'authorProfileImageUrl': authorProfileImageUrl,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'lastEdited': lastEdited?.toIso8601String(),
        'attachmentUrls': attachmentUrls,
      };
}