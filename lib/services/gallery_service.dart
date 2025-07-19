import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:living/models/gallery_item_model.dart';

class GalleryService {
  static const String _galleryKey = 'gallery_items';

  Future<List<GalleryItem>> getGalleryItems() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_galleryKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((e) => GalleryItem.fromJson(e)).toList();
  }

  Future<void> saveGalleryItems(List<GalleryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_galleryKey, jsonString);
  }

  Future<void> addGalleryItem(GalleryItem item) async {
    final items = await getGalleryItems();
    items.insert(0, item);
    await saveGalleryItems(items);
  }
} 