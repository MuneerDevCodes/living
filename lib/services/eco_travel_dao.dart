import 'package:firebase_database/firebase_database.dart';
import 'package:living/models/eco_travel_model.dart';
import 'package:living/services/auth_helper.dart';
import 'package:living/services/admin_service.dart';

class EcoTravelDAO {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref().child('eco_travel');

  // Get all verified eco-travel suggestions (for public display)
  static Future<List<EcoTravelSuggestion>> getAllEcoTravelSuggestions() async {
    try {
      final snapshot = await _database.orderByChild('status').equalTo('approved').get();
      List<EcoTravelSuggestion> suggestions = [];
      
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final value = child.value;
          if (value is Map) {
            final Map<String, dynamic> data = Map<String, dynamic>.from(value);
            suggestions.add(EcoTravelSuggestion.fromJson(child.key!, data));
          }
        }
      }
      
      // If no verified data exists, initialize with sample data
      if (suggestions.isEmpty) {
        await _initializeSampleData();
        return await getAllEcoTravelSuggestions();
      }
      
      return suggestions;
    } catch (e) {
      throw Exception('Failed to fetch eco-travel suggestions: $e');
    }
  }

  // Get all pending suggestions (for admin approval)
  static Future<List<EcoTravelSuggestion>> getPendingSuggestions() async {
    try {
      final snapshot = await _database.orderByChild('status').equalTo('pending').get();
      List<EcoTravelSuggestion> suggestions = [];
      
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final value = child.value;
          if (value is Map) {
            final Map<String, dynamic> data = Map<String, dynamic>.from(value);
            suggestions.add(EcoTravelSuggestion.fromJson(child.key!, data));
          }
        }
      }
      
      return suggestions;
    } catch (e) {
      throw Exception('Failed to fetch pending suggestions: $e');
    }
  }

  // Get all suggestions by a specific user
  static Future<List<EcoTravelSuggestion>> getUserSuggestions(String userId) async {
    try {
      final snapshot = await _database.orderByChild('createdBy').equalTo(userId).get();
      List<EcoTravelSuggestion> suggestions = [];
      
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final value = child.value;
          if (value is Map) {
            final Map<String, dynamic> data = Map<String, dynamic>.from(value);
            suggestions.add(EcoTravelSuggestion.fromJson(child.key!, data));
          }
        }
      }
      
      return suggestions;
    } catch (e) {
      throw Exception('Failed to fetch user suggestions: $e');
    }
  }

  // Get eco-travel suggestions by category (only approved)
  static Future<List<EcoTravelSuggestion>> getEcoTravelByCategory(String category) async {
    try {
      final allSuggestions = await getAllEcoTravelSuggestions();
      return allSuggestions.where((suggestion) => suggestion.category == category).toList();
    } catch (e) {
      throw Exception('Failed to fetch eco-travel suggestions by category: $e');
    }
  }

  // Get eco-travel suggestions by location (only approved)
  static Future<List<EcoTravelSuggestion>> getEcoTravelByLocation(String location) async {
    try {
      final allSuggestions = await getAllEcoTravelSuggestions();
      return allSuggestions.where((suggestion) => suggestion.location == location).toList();
    } catch (e) {
      throw Exception('Failed to fetch eco-travel suggestions by location: $e');
    }
  }

  // Search eco-travel suggestions (only approved)
  static Future<List<EcoTravelSuggestion>> searchEcoTravelSuggestions(String query) async {
    try {
      final allSuggestions = await getAllEcoTravelSuggestions();
      return allSuggestions.where((suggestion) =>
        suggestion.title.toLowerCase().contains(query.toLowerCase()) ||
        suggestion.description.toLowerCase().contains(query.toLowerCase()) ||
        suggestion.category.toLowerCase().contains(query.toLowerCase()) ||
        suggestion.location.toLowerCase().contains(query.toLowerCase())
      ).toList();
    } catch (e) {
      throw Exception('Failed to search eco-travel suggestions: $e');
    }
  }

  // Get popular destinations (only from approved suggestions)
  static Future<List<String>> getPopularDestinations() async {
    try {
      final suggestions = await getAllEcoTravelSuggestions();
      final locationCount = <String, int>{};
      
      for (var suggestion in suggestions) {
        locationCount[suggestion.location] = (locationCount[suggestion.location] ?? 0) + 1;
      }
      
      final sortedLocations = locationCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      return sortedLocations.take(10).map((e) => e.key).toList();
    } catch (e) {
      throw Exception('Failed to get popular destinations: $e');
    }
  }

  // Add new eco-travel suggestion with verification workflow
  static Future<void> addEcoTravelSuggestion(EcoTravelSuggestion suggestion) async {
    try {
      // Check if the creator is an admin
      final isAdmin = await AdminService().isAdmin();
      
      EcoTravelSuggestion finalSuggestion;
      if (isAdmin) {
        // Admin posts are automatically approved
        finalSuggestion = suggestion.copyWith(
          isVerified: true,
          status: 'approved',
          verifiedAt: DateTime.now(),
          verifiedBy: AuthService.getCurrentUserId(),
        );
      } else {
        // User posts need admin approval
        finalSuggestion = suggestion.copyWith(
          isVerified: false,
          status: 'pending',
        );
      }
      
      await _database.push().set(finalSuggestion.toJson());
    } catch (e) {
      throw Exception('Failed to add eco-travel suggestion: $e');
    }
  }

  // Approve a pending suggestion
  static Future<void> approveSuggestion(String key) async {
    try {
      final adminId = AuthService.getCurrentUserId();
      if (adminId == null) throw Exception('Admin not authenticated');
      
      await _database.child(key).update({
        'isVerified': true,
        'status': 'approved',
        'verifiedAt': DateTime.now().millisecondsSinceEpoch,
        'verifiedBy': adminId,
      });
    } catch (e) {
      throw Exception('Failed to approve suggestion: $e');
    }
  }

  // Reject a pending suggestion
  static Future<void> rejectSuggestion(String key) async {
    try {
      final adminId = AuthService.getCurrentUserId();
      if (adminId == null) throw Exception('Admin not authenticated');
      
      await _database.child(key).update({
        'isVerified': false,
        'status': 'rejected',
        'verifiedAt': DateTime.now().millisecondsSinceEpoch,
        'verifiedBy': adminId,
      });
    } catch (e) {
      throw Exception('Failed to reject suggestion: $e');
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

  // Initialize sample data with admin verification
  static Future<void> _initializeSampleData() async {
    final sampleSuggestions = [
      EcoTravelSuggestion(
        key: 'public_transit_nyc',
        title: 'Use NYC Subway System',
        description: 'New York City\'s extensive subway system is one of the most eco-friendly ways to explore the city. With 24/7 service and comprehensive coverage, you can reach almost anywhere without a car.',
        category: 'Transportation',
        location: 'New York City, USA',
        carbonImpact: 0.041,
        carbonUnit: 'kg CO2/km',
        benefits: [
          'Reduces traffic congestion',
          'Saves money on parking and fuel',
          'Provides 24/7 access to the city',
          'Connects to all major attractions',
          'Supports local economy'
        ],
        tips: [
          'Get a MetroCard for unlimited rides',
          'Use the MTA app for real-time updates',
          'Avoid rush hours when possible',
          'Combine with walking for short distances',
          'Keep your MetroCard handy'
        ],
        imageUrl: 'assets/icons/subway.png',
        createdBy: 'admin',
        createdByName: 'System Admin',
        createdAt: DateTime.now(),
        isVerified: true,
        status: 'approved',
        verifiedAt: DateTime.now(),
        verifiedBy: 'admin',
      ),
      EcoTravelSuggestion(
        key: 'bike_rental_amsterdam',
        title: 'Bike Rental in Amsterdam',
        description: 'Amsterdam is famous for its cycling culture. Rent a bike to explore the city like a local while reducing your carbon footprint and experiencing the authentic Dutch way of life.',
        category: 'Transportation',
        location: 'Amsterdam, Netherlands',
        carbonImpact: 0.0,
        carbonUnit: 'kg CO2/km',
        benefits: [
          'Zero carbon emissions',
          'Healthy exercise while sightseeing',
          'Access to bike-only paths',
          'Authentic local experience',
          'Cost-effective transportation'
        ],
        tips: [
          'Rent from reputable shops',
          'Always lock your bike securely',
          'Follow local cycling rules',
          'Use bike lanes when available',
          'Consider guided bike tours'
        ],
        imageUrl: 'assets/icons/bike.png',
        createdBy: 'admin',
        createdByName: 'System Admin',
        createdAt: DateTime.now(),
        isVerified: true,
        status: 'approved',
        verifiedAt: DateTime.now(),
        verifiedBy: 'admin',
      ),
      // Add more sample data with proper verification fields...
    ];

    try {
      for (var suggestion in sampleSuggestions) {
        await _database.push().set(suggestion.toJson());
      }
    } catch (e) {
      throw Exception('Failed to initialize sample data: $e');
    }
  }
} 