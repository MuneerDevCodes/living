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

  Future<List<ForumPost>> getPublishedPosts() async {
    final snapshot = await _databaseRef.get();
    final List<ForumPost> posts = [];
    if (snapshot.exists) {
      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        posts.add(ForumPost.fromJson(key.toString(), value as Map<dynamic, dynamic>));
      });
    }
    return posts;
  }

  Future<ForumPost?> getForumPostById(String postId) async {
    final snapshot = await _databaseRef.child(postId).get();
    if (snapshot.exists) {
      return ForumPost.fromJson(postId, snapshot.value as Map<dynamic, dynamic>);
    }
    return null;
  }

  Future<void> updateLikes(String key, int newLikes) async {
    await _databaseRef.child(key).update({'likes': newLikes});
  }

  Future<void> addComment(String postKey, ForumComment comment) async {
    final snapshot = await _databaseRef.child(postKey).child('comments').get();
    List<dynamic> comments = [];
    if (snapshot.exists) {
      comments = List<dynamic>.from(snapshot.value as List<dynamic>);
    }
    comments.add(comment.toJson());
    await _databaseRef.child(postKey).update({'comments': comments});
  }
}
