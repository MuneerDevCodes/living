import 'package:firebase_database/firebase_database.dart';
import '../models/forum_post_model.dart';

class ForumPostDao {
  final _databaseRef = FirebaseDatabase.instance.ref("forumPosts");

  void saveForumPost(ForumPost post) {
    _databaseRef.push().set(post.toJson());
  }

  Query getForumPostList() {
    return _databaseRef;
  }

  void deleteForumPost(String key) {
    _databaseRef.child(key).remove();
  }

  void updateForumPost(String key, ForumPost post) {
    _databaseRef.child(key).update(post.toMap());
  }

  Future<ForumPost?> getForumPostById(String postId) async {
    final snapshot = await _databaseRef.child(postId).get();
    if (snapshot.exists) {
      return ForumPost.fromJson(postId, snapshot.value as Map<dynamic, dynamic>);
    }
    return null;
  }

  // New methods for the forum page
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

  Future<void> addPost(ForumPost post) async {
    await _databaseRef.push().set(post.toJson());
  }

  Future<void> updatePost(ForumPost post) async {
    await _databaseRef.child(post.key).update(post.toMap());
  }

  Future<void> deletePost(String key) async {
    await _databaseRef.child(key).remove();
  }
}
