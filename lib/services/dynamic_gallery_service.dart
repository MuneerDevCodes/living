import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/gallery_item_model.dart';
import 'gallery_dao.dart';
import 'user_dao.dart';

class DynamicGalleryService {
  final GalleryDao _galleryDao = GalleryDao();
  final UserDao _userDao = UserDao();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream controllers for real-time updates
  StreamController<List<GalleryItem>>? _galleryController;
  StreamController<List<GalleryItem>>? _pendingApprovalController;

  // Current user info
  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserEmail => _auth.currentUser?.email;

  // Get approved gallery items stream (for regular users)
  Stream<List<GalleryItem>> getApprovedGalleryItemsStream() {
    return _galleryDao.getApprovedGalleryItemsStream();
  }

  // Get all gallery items stream (for admin)
  Stream<List<GalleryItem>> getAllGalleryItemsStream() {
    return _galleryDao.getGalleryItemsStream();
  }

  // Get pending approval items stream (for admin)
  Stream<List<GalleryItem>> getPendingApprovalStream() {
    return _galleryDao.getPendingApprovalStream();
  }

  // Get gallery items by category
  Stream<List<GalleryItem>> getGalleryItemsByCategoryStream(String category) {
    if (category == 'All') {
      return getApprovedGalleryItemsStream();
    }
    return _galleryDao.getGalleryItemsByCategoryStream(category);
  }

  // Search gallery items
  Stream<List<GalleryItem>> searchGalleryItemsStream(String query) {
    return _galleryDao.searchGalleryItemsStream(query);
  }

  // Get user's uploaded items
  Stream<List<GalleryItem>> getUserGalleryItemsStream() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }
    return _galleryDao.getUserGalleryItemsStream(userId);
  }

  // Add new gallery item
  Future<String> addGalleryItem(GalleryItem item) async {
    try {
      // Set user info
      final userId = currentUserId;
      final userEmail = currentUserEmail;
      
      final itemWithUserInfo = item.copyWith(
        uploadedBy: userEmail ?? userId ?? 'anonymous',
        uploadedAt: DateTime.now(),
        approved: await _isAdmin() ? true : false, // Auto-approve for admins
        adminApproved: await _isAdmin(),
      );

      // Save to database
      final key = await _galleryDao.saveGalleryItem(itemWithUserInfo);
      
      return key;
    } catch (e) {
      throw Exception('Failed to add gallery item: $e');
    }
  }

  // Update gallery item
  Future<void> updateGalleryItem(String key, GalleryItem item) async {
    try {
      await _galleryDao.updateGalleryItem(key, item);
    } catch (e) {
      throw Exception('Failed to update gallery item: $e');
    }
  }

  // Delete gallery item
  Future<void> deleteGalleryItem(String key) async {
    try {
      // Check if user is admin or owner of the item
      final canDelete = await _canDeleteItem(key);
      if (!canDelete) {
        throw Exception('You do not have permission to delete this item');
      }

      await _galleryDao.deleteGalleryItem(key);
    } catch (e) {
      throw Exception('Failed to delete gallery item: $e');
    }
  }

  // Like gallery item
  Future<void> likeGalleryItem(String key, int currentLikes) async {
    try {
      await _galleryDao.likeGalleryItem(key, currentLikes + 1);
    } catch (e) {
      throw Exception('Failed to like gallery item: $e');
    }
  }

  // Add comment to gallery item
  Future<void> addCommentToGalleryItem(String key, int currentComments) async {
    try {
      await _galleryDao.addCommentToGalleryItem(key, currentComments + 1);
    } catch (e) {
      throw Exception('Failed to add comment to gallery item: $e');
    }
  }

  // Approve gallery item (admin only)
  Future<void> approveGalleryItem(String key, bool approved) async {
    try {
      if (!await _isAdmin()) {
        throw Exception('Only admins can approve gallery items');
      }

      await _galleryDao.approveGalleryItem(key, approved);
    } catch (e) {
      throw Exception('Failed to approve gallery item: $e');
    }
  }

  // Check if current user is admin
  Future<bool> _isAdmin() async {
    try {
      final userId = currentUserId;
      if (userId == null) return false;

      final userRole = await _userDao.getUserRole(userId);
      return userRole == 'admin';
    } catch (e) {
      return false;
    }
  }

  // Check if user can delete an item (admin or owner)
  Future<bool> _canDeleteItem(String key) async {
    try {
      final isAdmin = await _isAdmin();
      if (isAdmin) return true;

      // Check if user is the owner of the item
      final userId = currentUserId;
      if (userId == null) return false;

      // Get the item to check ownership
      final allItems = await _galleryDao.getGalleryItemsStream().first;
      final item = allItems.firstWhere((item) => item.id == key);
      
      return item.uploadedBy == currentUserEmail || item.uploadedBy == userId;
    } catch (e) {
      return false;
    }
  }

  // Get user permissions
  Future<Map<String, bool>> getUserPermissions() async {
    final isAdmin = await _isAdmin();
    final isLoggedIn = currentUserId != null;

    return {
      'isAdmin': isAdmin,
      'isLoggedIn': isLoggedIn,
      'canUpload': isLoggedIn,
      'canDelete': isAdmin,
      'canApprove': isAdmin,
      'canEdit': isAdmin,
    };
  }

  // Initialize sample data (admin only)
  Future<void> initializeSampleData() async {
    try {
      if (!await _isAdmin()) {
        throw Exception('Only admins can initialize sample data');
      }

      final sampleItems = [
        GalleryItem(
          id: 'sample-1',
          title: 'Beautiful Nature',
          description: 'A stunning view of natural landscapes and wildlife.',
          imageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400',
          category: 'Nature',
          likes: 15,
          comments: 3,
          uploadedBy: 'admin',
          uploadedAt: DateTime.now(),
          approved: true,
          adminApproved: true,
        ),
        GalleryItem(
          id: 'sample-2',
          title: 'Sustainable Living',
          description: 'Eco-friendly practices for a better future.',
          imageUrl: 'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?w=400',
          category: 'Sustainability',
          likes: 23,
          comments: 7,
          uploadedBy: 'admin',
          uploadedAt: DateTime.now(),
          approved: true,
          adminApproved: true,
        ),
        GalleryItem(
          id: 'sample-3',
          title: 'Community Garden',
          description: 'Local community working together for green spaces.',
          imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=400',
          category: 'Community',
          likes: 18,
          comments: 5,
          uploadedBy: 'admin',
          uploadedAt: DateTime.now(),
          approved: true,
          adminApproved: true,
        ),
        GalleryItem(
          id: 'sample-4',
          title: 'Eco Event',
          description: 'Environmental awareness event in our city.',
          imageUrl: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=400',
          category: 'Events',
          likes: 31,
          comments: 12,
          uploadedBy: 'admin',
          uploadedAt: DateTime.now(),
          approved: true,
          adminApproved: true,
        ),
        GalleryItem(
          id: 'sample-5',
          title: 'Green Technology',
          description: 'Innovative solutions for environmental challenges.',
          imageUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=400',
          category: 'Sustainability',
          likes: 27,
          comments: 9,
          uploadedBy: 'admin',
          uploadedAt: DateTime.now(),
          approved: true,
          adminApproved: true,
        ),
        GalleryItem(
          id: 'sample-6',
          title: 'Wildlife Conservation',
          description: 'Protecting endangered species and their habitats.',
          imageUrl: 'https://images.unsplash.com/photo-1564349683136-77e08dba1ef7?w=400',
          category: 'Nature',
          likes: 42,
          comments: 15,
          uploadedBy: 'admin',
          uploadedAt: DateTime.now(),
          approved: true,
          adminApproved: true,
        ),
      ];

      for (final item in sampleItems) {
        await _galleryDao.saveGalleryItem(item);
      }
    } catch (e) {
      throw Exception('Failed to initialize sample data: $e');
    }
  }

  // Dispose resources
  void dispose() {
    _galleryController?.close();
    _pendingApprovalController?.close();
  }
} 