class ForumPost {
  final String userId;
  final String title;
  final String message;
  final String timestamp;

  ForumPost({
    required this.userId,
    required this.title,
    required this.message,
    required this.timestamp,
  });

  ForumPost.fromJson(Map<dynamic, dynamic> json)
      : userId = json['userId'] as String,
        title = json['title'] as String,
        message = json['message'] as String,
        timestamp = json['timestamp'] as String;

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'userId': userId,
        'title': title,
        'message': message,
        'timestamp': timestamp,
      };

  Map<String, dynamic> toMap() => <String, dynamic>{
        'userId': userId,
        'title': title,
        'message': message,
        'timestamp': timestamp,
      };
}