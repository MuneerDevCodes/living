import 'package:firebase_database/firebase_database.dart';
import 'package:living/models/educational_content_model.dart';

class EducationalContentDAO {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref().child('educational_content');

  // Get all published educational content
  static Future<List<EducationalContent>> getPublishedContent() async {
    try {
      final snapshot = await _database.orderByChild('isPublished').equalTo(true).get();
      List<EducationalContent> content = [];
      
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          content.add(EducationalContent.fromJson(child.key!, child.value as Map<String, dynamic>));
        }
      }
      
      return content;
    } catch (e) {
      throw Exception('Failed to fetch educational content: $e');
    }
  }

  // Get educational content by category
  static Future<List<EducationalContent>> getContentByCategory(String category) async {
    try {
      final snapshot = await _database.orderByChild('category').equalTo(category).get();
      List<EducationalContent> content = [];
      
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final contentItem = EducationalContent.fromJson(child.key!, child.value as Map<String, dynamic>);
          if (contentItem.isPublished) {
            content.add(contentItem);
          }
        }
      }
      
      return content;
    } catch (e) {
      throw Exception('Failed to fetch educational content by category: $e');
    }
  }

  // Get educational content by content type
  static Future<List<EducationalContent>> getContentByType(String contentType) async {
    try {
      final snapshot = await _database.orderByChild('contentType').equalTo(contentType).get();
      List<EducationalContent> content = [];
      
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final contentItem = EducationalContent.fromJson(child.key!, child.value as Map<String, dynamic>);
          if (contentItem.isPublished) {
            content.add(contentItem);
          }
        }
      }
      
      return content;
    } catch (e) {
      throw Exception('Failed to fetch educational content by type: $e');
    }
  }

  // Add new educational content (admin only)
  static Future<void> addEducationalContent(EducationalContent content) async {
    try {
      await _database.push().set(content.toJson());
    } catch (e) {
      throw Exception('Failed to add educational content: $e');
    }
  }

  // Update educational content (admin only)
  static Future<void> updateEducationalContent(EducationalContent content) async {
    try {
      await _database.child(content.key).update(content.toJson());
    } catch (e) {
      throw Exception('Failed to update educational content: $e');
    }
  }

  // Delete educational content (admin only)
  static Future<void> deleteEducationalContent(String key) async {
    try {
      await _database.child(key).remove();
    } catch (e) {
      throw Exception('Failed to delete educational content: $e');
    }
  }
} 