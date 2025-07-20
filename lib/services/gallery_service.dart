import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:living/models/gallery_item_model.dart';

class GalleryService {
  static const String _galleryKey = 'gallery_items';
  static const String _initializedKey = 'gallery_initialized';

  // Stream controller for real-time updates
  final List<GalleryItem> _items = [];
  bool _isInitialized = false;

  Future<List<GalleryItem>> getGalleryItems() async {
    if (!_isInitialized) {
      await _initializeData();
    }
    return List.from(_items);
  }

  Future<void> _initializeData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isInitialized = prefs.getBool(_initializedKey) ?? false;
      
      if (!isInitialized) {
        // Initialize with sample data
        await _initializeSampleData();
        await prefs.setBool(_initializedKey, true);
      } else {
        // Load existing data
        await _loadFromStorage();
      }
      _isInitialized = true;
    } catch (e) {
      // If initialization fails, try to initialize with sample data
      try {
        await _initializeSampleData();
        _isInitialized = true;
      } catch (e2) {
        _isInitialized = true; // Set to true to prevent infinite retries
      }
    }
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_galleryKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(jsonString);
        _items.clear();
        _items.addAll(jsonList.map((e) => GalleryItem.fromJson(e)).toList());
      }
    } catch (e) {
      _items.clear();
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Filter out items with large binary data for storage
      final itemsForStorage = _items.map((item) {
        // Create a copy without webImageBytes for storage
        return {
          'id': item.id,
          'title': item.title,
          'description': item.description,
          'imageUrl': item.imageUrl,
          'category': item.category,
          'likes': item.likes,
          'comments': item.comments,
          'isLocal': item.isLocal,
          'isWebMemory': item.isWebMemory,
          // Note: webImageBytes are stored in memory only for performance
          // They will be lost on app restart, but this is acceptable for a demo
          // In a production app, you would use a proper file storage system
        };
      }).toList();
      
      final jsonString = json.encode(itemsForStorage);
      await prefs.setString(_galleryKey, jsonString);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _initializeSampleData() async {
    _items.clear();
    
    // Add sample gallery items
    final sampleItems = [
      GalleryItem(
        id: '1',
        title: 'Beautiful Nature',
        description: 'A stunning view of natural landscapes and wildlife.',
        imageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400',
        category: 'Nature',
        likes: 15,
        comments: 3,
      ),
      GalleryItem(
        id: '2',
        title: 'Sustainable Living',
        description: 'Eco-friendly practices for a better future.',
        imageUrl: 'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?w=400',
        category: 'Sustainability',
        likes: 23,
        comments: 7,
      ),
      GalleryItem(
        id: '3',
        title: 'Community Garden',
        description: 'Local community working together for green spaces.',
        imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=400',
        category: 'Community',
        likes: 18,
        comments: 5,
      ),
      GalleryItem(
        id: '4',
        title: 'Eco Event',
        description: 'Environmental awareness event in our city.',
        imageUrl: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=400',
        category: 'Events',
        likes: 31,
        comments: 12,
      ),
      GalleryItem(
        id: '5',
        title: 'Green Technology',
        description: 'Innovative solutions for environmental challenges.',
        imageUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=400',
        category: 'Sustainability',
        likes: 27,
        comments: 9,
      ),
      GalleryItem(
        id: '6',
        title: 'Wildlife Conservation',
        description: 'Protecting endangered species and their habitats.',
        imageUrl: 'https://images.unsplash.com/photo-1564349683136-77e08dba1ef7?w=400',
        category: 'Nature',
        likes: 42,
        comments: 15,
      ),
    ];

    _items.addAll(sampleItems);
    await _saveToStorage();
  }

  Future<void> addGalleryItem(GalleryItem item) async {
    try {
      if (!_isInitialized) {
        await _initializeData();
      }
      
      // Add to memory
      _items.insert(0, item);
      
      // Save to storage
      await _saveToStorage();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateGalleryItem(GalleryItem updatedItem) async {
    if (!_isInitialized) {
      await _initializeData();
    }
    
    final index = _items.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _items[index] = updatedItem;
      await _saveToStorage();
    }
  }

  Future<void> deleteGalleryItem(String id) async {
    if (!_isInitialized) {
      await _initializeData();
    }
    
    _items.removeWhere((item) => item.id == id);
    await _saveToStorage();
  }

  Future<void> likeGalleryItem(String id) async {
    if (!_isInitialized) {
      await _initializeData();
    }
    
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      final item = _items[index];
      final updatedItem = GalleryItem(
        id: item.id,
        title: item.title,
        description: item.description,
        imageUrl: item.imageUrl,
        category: item.category,
        likes: item.likes + 1,
        comments: item.comments,
        isLocal: item.isLocal,
        isWebMemory: item.isWebMemory,
        webImageBytes: item.webImageBytes,
      );
      _items[index] = updatedItem;
      await _saveToStorage();
    }
  }

  Future<void> addCommentToGalleryItem(String id) async {
    if (!_isInitialized) {
      await _initializeData();
    }
    
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      final item = _items[index];
      final updatedItem = GalleryItem(
        id: item.id,
        title: item.title,
        description: item.description,
        imageUrl: item.imageUrl,
        category: item.category,
        likes: item.likes,
        comments: item.comments + 1,
        isLocal: item.isLocal,
        isWebMemory: item.isWebMemory,
        webImageBytes: item.webImageBytes,
      );
      _items[index] = updatedItem;
      await _saveToStorage();
    }
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_galleryKey);
    await prefs.remove(_initializedKey);
    _items.clear();
    _isInitialized = false;
  }

  // Method to get items by category
  Future<List<GalleryItem>> getGalleryItemsByCategory(String category) async {
    if (!_isInitialized) {
      await _initializeData();
    }
    
    if (category == 'All') {
      return List.from(_items);
    }
    return _items.where((item) => item.category == category).toList();
  }

  // Method to search items
  Future<List<GalleryItem>> searchGalleryItems(String query) async {
    if (!_isInitialized) {
      await _initializeData();
    }
    
    final lowercaseQuery = query.toLowerCase();
    return _items.where((item) =>
        item.title.toLowerCase().contains(lowercaseQuery) ||
        item.description.toLowerCase().contains(lowercaseQuery) ||
        item.category.toLowerCase().contains(lowercaseQuery)).toList();
  }
} 