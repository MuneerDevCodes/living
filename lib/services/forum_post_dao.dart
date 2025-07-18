import 'package:firebase_database/firebase_database.dart';
import '../models/forum_post_model.dart';

class ForumPostDao {
  final _databaseRef = FirebaseDatabase.instance.ref("forumPosts");

  Future<void> addPost(ForumPost post) async {
    await _databaseRef.push().set(post.toJson());
  }

  Future<void> updatePost(ForumPost post) async {
    await _databaseRef.child(post.key).update(post.toMap());
  }

  Future<void> deletePost(String key) async {
    await _databaseRef.child(key).remove();
  }

  Future<List<ForumPost>> getPublishedPosts({List<String>? tags, String? status}) async {
    final snapshot = await _databaseRef.get();
    final List<ForumPost> posts = [];
    if (snapshot.exists) {
      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        final post = ForumPost.fromJson(key.toString(), Map<String, dynamic>.from(value as Map));
        if ((tags == null || tags.any((tag) => post.tags.contains(tag))) &&
            (status == null || post.status == status)) {
          posts.add(post);
        }
      });
    }
    return posts;
  }

  Future<ForumPost?> getForumPostById(String postId) async {
    final snapshot = await _databaseRef.child(postId).get();
    if (snapshot.exists) {
      return ForumPost.fromJson(postId, Map<String, dynamic>.from(snapshot.value as Map));
    }
    return null;
  }

  Future<void> updateLikes(String key, int newLikes) async {
    await _databaseRef.child(key).update({'likes': newLikes});
  }

  // Comments as sub-nodes
  DatabaseReference _commentsRef(String postKey) => _databaseRef.child(postKey).child('comments');

  Future<List<ForumComment>> getComments(String postKey, {int? limit, String? startAfterKey}) async {
    Query query = _commentsRef(postKey);
    if (limit != null) {
      query = query.limitToFirst(limit);
    }
    final snapshot = await query.get();
    final List<ForumComment> comments = [];
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        data.forEach((key, value) {
          comments.add(ForumComment.fromJson({...Map<String, dynamic>.from(value as Map), 'key': key}));
        });
      }
    }
    return comments;
  }

  Future<void> addComment(String postKey, ForumComment comment) async {
    final newCommentRef = _commentsRef(postKey).push();
    await newCommentRef.set(comment.toJson());
  }

  Future<void> updateComment(String postKey, String commentKey, ForumComment comment) async {
    await _commentsRef(postKey).child(commentKey).update(Map<String, Object?>.from(comment.toJson()));
  }

  Future<void> deleteComment(String postKey, String commentKey) async {
    await _commentsRef(postKey).child(commentKey).remove();
  }
}
