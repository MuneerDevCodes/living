import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import '../models/gallery_item_model.dart';

class GalleryDao {
  final _databaseRef = FirebaseDatabase.instance.ref("gallery");
  final _storageRef = FirebaseStorage.instance.ref("gallery_images");

  // Save gallery item to database
  Future<String> saveGalleryItem(GalleryItem item) async {
    try {
      // If item has webImageBytes, upload to Firebase Storage first
      String imageUrl = item.imageUrl;
      if (item.webImageBytes != null) {
        final imageRef = _storageRef.child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        await imageRef.putData(item.webImageBytes!);
        imageUrl = await imageRef.getDownloadURL();
      }

      // Create item for database (without webImageBytes)
      final itemForDb = {
        'id': item.id,
        'title': item.title,
        'description': item.description,
        'imageUrl': imageUrl,
        'category': item.category,
        'likes': item.likes,
        'comments': item.comments,
        'isLocal': false, // All items in DB are considered remote
        'isWebMemory': false,
        'uploadedBy': item.uploadedBy ?? 'anonymous',
        'uploadedAt': item.uploadedAt ?? DateTime.now().toIso8601String(),
        'approved': item.approved ?? true, // Default to approved
        'adminApproved': item.adminApproved ?? false,
      };

      final newRef = _databaseRef.push();
      await newRef.set(itemForDb);
      return newRef.key!;
    } catch (e) {
      throw Exception('Failed to save gallery item: $e');
    }
  }

  // Get all gallery items as stream for real-time updates
  Stream<List<GalleryItem>> getGalleryItemsStream() {
    return _databaseRef.onValue.map((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        final List<GalleryItem> items = [];
        
        data.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            try {
              final item = GalleryItem.fromJson(Map<String, dynamic>.from(value));
              items.add(item);
            } catch (e) {
              print('Error parsing gallery item: $e');
            }
          }
        });
        
        // Sort by upload date (newest first)
        items.sort((a, b) => (b.uploadedAt ?? DateTime.now())
            .compareTo(a.uploadedAt ?? DateTime.now()));
        
        return items;
      }
      return [];
    });
  }

  // Get approved gallery items only
  Stream<List<GalleryItem>> getApprovedGalleryItemsStream() {
    return _databaseRef
        .orderByChild('approved')
        .equalTo(true)
        .onValue
        .map((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        final List<GalleryItem> items = [];
        
        data.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            try {
              final item = GalleryItem.fromJson(Map<String, dynamic>.from(value));
              items.add(item);
            } catch (e) {
              print('Error parsing gallery item: $e');
            }
          }
        });
        
        // Sort by upload date (newest first)
        items.sort((a, b) => (b.uploadedAt ?? DateTime.now())
            .compareTo(a.uploadedAt ?? DateTime.now()));
        
        return items;
      }
      return [];
    });
  }

  // Get pending approval items (for admin)
  Stream<List<GalleryItem>> getPendingApprovalStream() {
    return _databaseRef
        .orderByChild('approved')
        .equalTo(false)
        .onValue
        .map((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        final List<GalleryItem> items = [];
        
        data.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            try {
              final item = GalleryItem.fromJson(Map<String, dynamic>.from(value));
              items.add(item);
            } catch (e) {
              print('Error parsing gallery item: $e');
            }
          }
        });
        
        return items;
      }
      return [];
    });
  }

  // Update gallery item
  Future<void> updateGalleryItem(String key, GalleryItem item) async {
    try {
      final itemForDb = {
        'id': item.id,
        'title': item.title,
        'description': item.description,
        'imageUrl': item.imageUrl,
        'category': item.category,
        'likes': item.likes,
        'comments': item.comments,
        'isLocal': false,
        'isWebMemory': false,
        'uploadedBy': item.uploadedBy,
        'uploadedAt': item.uploadedAt?.toIso8601String(),
        'approved': item.approved,
        'adminApproved': item.adminApproved,
      };

      await _databaseRef.child(key).update(itemForDb);
    } catch (e) {
      throw Exception('Failed to update gallery item: $e');
    }
  }

  // Delete gallery item
  Future<void> deleteGalleryItem(String key) async {
    try {
      // Get the item first to delete the image from storage
      final snapshot = await _databaseRef.child(key).get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final imageUrl = data['imageUrl'] as String?;
        
        // Delete from storage if it's a Firebase Storage URL
        if (imageUrl != null && imageUrl.contains('firebasestorage')) {
          try {
            final imageRef = FirebaseStorage.instance.refFromURL(imageUrl);
            await imageRef.delete();
          } catch (e) {
            print('Failed to delete image from storage: $e');
          }
        }
      }
      
      // Delete from database
      await _databaseRef.child(key).remove();
    } catch (e) {
      throw Exception('Failed to delete gallery item: $e');
    }
  }

  // Like gallery item
  Future<void> likeGalleryItem(String key, int likes) async {
    try {
      await _databaseRef.child(key).update({'likes': likes});
    } catch (e) {
      throw Exception('Failed to like gallery item: $e');
    }
  }

  // Add comment to gallery item
  Future<void> addCommentToGalleryItem(String key, int comments) async {
    try {
      await _databaseRef.child(key).update({'comments': comments});
    } catch (e) {
      throw Exception('Failed to add comment to gallery item: $e');
    }
  }

  // Approve gallery item (admin function)
  Future<void> approveGalleryItem(String key, bool approved) async {
    try {
      await _databaseRef.child(key).update({
        'approved': approved,
        'adminApproved': true,
      });
    } catch (e) {
      throw Exception('Failed to approve gallery item: $e');
    }
  }

  // Get gallery items by category
  Stream<List<GalleryItem>> getGalleryItemsByCategoryStream(String category) {
    return _databaseRef
        .orderByChild('category')
        .equalTo(category)
        .onValue
        .map((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        final List<GalleryItem> items = [];
        
        data.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            try {
              final item = GalleryItem.fromJson(Map<String, dynamic>.from(value));
              if (item.approved ?? true) {
                items.add(item);
              }
            } catch (e) {
              print('Error parsing gallery item: $e');
            }
          }
        });
        
        return items;
      }
      return [];
    });
  }

  // Search gallery items
  Stream<List<GalleryItem>> searchGalleryItemsStream(String query) {
    return _databaseRef.onValue.map((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        final List<GalleryItem> items = [];
        final lowercaseQuery = query.toLowerCase();
        
        data.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            try {
              final item = GalleryItem.fromJson(Map<String, dynamic>.from(value));
              if ((item.approved ?? true) &&
                  (item.title.toLowerCase().contains(lowercaseQuery) ||
                   item.description.toLowerCase().contains(lowercaseQuery) ||
                   item.category.toLowerCase().contains(lowercaseQuery))) {
                items.add(item);
              }
            } catch (e) {
              print('Error parsing gallery item: $e');
            }
          }
        });
        
        return items;
      }
      return [];
    });
  }

  // Get user's uploaded items
  Stream<List<GalleryItem>> getUserGalleryItemsStream(String userId) {
    return _databaseRef
        .orderByChild('uploadedBy')
        .equalTo(userId)
        .onValue
        .map((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        final List<GalleryItem> items = [];
        
        data.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            try {
              final item = GalleryItem.fromJson(Map<String, dynamic>.from(value));
              items.add(item);
            } catch (e) {
              print('Error parsing gallery item: $e');
            }
          }
        });
        
        return items;
      }
      return [];
    });
  }
} 