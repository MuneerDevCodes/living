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
      return ForumPost.fromJson(snapshot.value as Map<dynamic, dynamic>);
    }
    return null;
  }
}
