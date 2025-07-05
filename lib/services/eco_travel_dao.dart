import 'package:firebase_database/firebase_database.dart';
import 'package:living/models/eco_travel_model.dart';

class EcoTravelDAO {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref().child('eco_travel');

  // Get all eco-travel suggestions
  static Future<List<EcoTravelSuggestion>> getAllEcoTravelSuggestions() async {
    try {
      final snapshot = await _database.get();
      List<EcoTravelSuggestion> suggestions = [];
      
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          suggestions.add(EcoTravelSuggestion.fromJson(child.key!, child.value as Map<String, dynamic>));
        }
      }
      
      return suggestions;
    } catch (e) {
      throw Exception('Failed to fetch eco-travel suggestions: $e');
    }
  }

  // Get eco-travel suggestions by category
  static Future<List<EcoTravelSuggestion>> getEcoTravelByCategory(String category) async {
    try {
      final snapshot = await _database.orderByChild('category').equalTo(category).get();
      List<EcoTravelSuggestion> suggestions = [];
      
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          suggestions.add(EcoTravelSuggestion.fromJson(child.key!, child.value as Map<String, dynamic>));
        }
      }
      
      return suggestions;
    } catch (e) {
      throw Exception('Failed to fetch eco-travel suggestions by category: $e');
    }
  }

  // Get eco-travel suggestions by location
  static Future<List<EcoTravelSuggestion>> getEcoTravelByLocation(String location) async {
    try {
      final snapshot = await _database.orderByChild('location').equalTo(location).get();
      List<EcoTravelSuggestion> suggestions = [];
      
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          suggestions.add(EcoTravelSuggestion.fromJson(child.key!, child.value as Map<String, dynamic>));
        }
      }
      
      return suggestions;
    } catch (e) {
      throw Exception('Failed to fetch eco-travel suggestions by location: $e');
    }
  }

  // Add new eco-travel suggestion (admin only)
  static Future<void> addEcoTravelSuggestion(EcoTravelSuggestion suggestion) async {
    try {
      await _database.push().set(suggestion.toJson());
    } catch (e) {
      throw Exception('Failed to add eco-travel suggestion: $e');
    }
  }

  // Update eco-travel suggestion (admin only)
  static Future<void> updateEcoTravelSuggestion(EcoTravelSuggestion suggestion) async {
    try {
      await _database.child(suggestion.key).update(suggestion.toJson());
    } catch (e) {
      throw Exception('Failed to update eco-travel suggestion: $e');
    }
  }

  // Delete eco-travel suggestion (admin only)
  static Future<void> deleteEcoTravelSuggestion(String key) async {
    try {
      await _database.child(key).remove();
    } catch (e) {
      throw Exception('Failed to delete eco-travel suggestion: $e');
    }
  }
} 