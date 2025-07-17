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
          final value = child.value;
          if (value is Map) {
            final Map<String, dynamic> data = Map<String, dynamic>.from(value);
            suggestions.add(EcoTravelSuggestion.fromJson(child.key!, data));
          }
        }
      }
      
      // If no data exists, initialize with sample data
      if (suggestions.isEmpty) {
        await _initializeSampleData();
        return await getAllEcoTravelSuggestions();
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
          final value = child.value;
          if (value is Map) {
            final Map<String, dynamic> data = Map<String, dynamic>.from(value);
            suggestions.add(EcoTravelSuggestion.fromJson(child.key!, data));
          }
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
          final value = child.value;
          if (value is Map) {
            final Map<String, dynamic> data = Map<String, dynamic>.from(value);
            suggestions.add(EcoTravelSuggestion.fromJson(child.key!, data));
          }
        }
      }
      
      return suggestions;
    } catch (e) {
      throw Exception('Failed to fetch eco-travel suggestions by location: $e');
    }
  }

  // Search eco-travel suggestions
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

  // Get popular destinations
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

  // Initialize sample data
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
        isVerified: true,
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
        isVerified: true,
      ),
      EcoTravelSuggestion(
        key: 'eco_hotel_costa_rica',
        title: 'Stay at Eco-Lodges in Costa Rica',
        description: 'Costa Rica offers numerous eco-friendly accommodations that blend luxury with sustainability. These lodges use renewable energy, support local communities, and protect biodiversity.',
        category: 'Accommodation',
        location: 'Costa Rica',
        carbonImpact: -2.5,
        carbonUnit: 'kg CO2/night',
        benefits: [
          'Supports conservation efforts',
          'Provides authentic local experience',
          'Uses renewable energy sources',
          'Supports local communities',
          'Educational about sustainability'
        ],
        tips: [
          'Book well in advance',
          'Choose certified eco-lodges',
          'Participate in local activities',
          'Respect wildlife and nature',
          'Learn about conservation projects'
        ],
        imageUrl: 'assets/icons/eco_lodge.png',
        isVerified: true,
      ),
      EcoTravelSuggestion(
        key: 'farm_to_table_paris',
        title: 'Farm-to-Table Restaurants in Paris',
        description: 'Paris has embraced the farm-to-table movement with restaurants that source ingredients locally and seasonally, reducing food miles and supporting sustainable agriculture.',
        category: 'Food & Dining',
        location: 'Paris, France',
        carbonImpact: 0.8,
        carbonUnit: 'kg CO2/meal',
        benefits: [
          'Fresher, more nutritious food',
          'Supports local farmers',
          'Reduces transportation emissions',
          'Seasonal menu variety',
          'Authentic French cuisine'
        ],
        tips: [
          'Make reservations in advance',
          'Ask about seasonal specialties',
          'Support restaurants with organic options',
          'Try local wine pairings',
          'Learn about French food culture'
        ],
        imageUrl: 'assets/icons/farm_table.png',
        isVerified: true,
      ),
      EcoTravelSuggestion(
        key: 'sustainable_shopping_tokyo',
        title: 'Sustainable Shopping in Tokyo',
        description: 'Tokyo offers numerous opportunities for sustainable shopping, from vintage clothing stores to zero-waste shops and traditional markets selling local crafts.',
        category: 'Shopping',
        location: 'Tokyo, Japan',
        carbonImpact: 0.3,
        carbonUnit: 'kg CO2/purchase',
        benefits: [
          'Reduces fast fashion impact',
          'Supports local artisans',
          'Unique, high-quality items',
          'Cultural experience',
          'Minimizes packaging waste'
        ],
        tips: [
          'Visit vintage districts like Harajuku',
          'Shop at traditional markets',
          'Bring reusable shopping bags',
          'Support local craft shops',
          'Choose quality over quantity'
        ],
        imageUrl: 'assets/icons/sustainable_shop.png',
        isVerified: true,
      ),
      EcoTravelSuggestion(
        key: 'volunteer_reef_australia',
        title: 'Volunteer for Reef Conservation',
        description: 'Join conservation programs in Australia\'s Great Barrier Reef to help protect marine ecosystems while learning about marine biology and sustainability.',
        category: 'Activities',
        location: 'Great Barrier Reef, Australia',
        carbonImpact: -1.2,
        carbonUnit: 'kg CO2/day',
        benefits: [
          'Direct conservation impact',
          'Educational experience',
          'Supports marine research',
          'Unique travel experience',
          'Contributes to global sustainability'
        ],
        tips: [
          'Choose certified programs',
          'Learn about marine conservation',
          'Follow safety guidelines',
          'Document your experience',
          'Share knowledge with others'
        ],
        imageUrl: 'assets/icons/reef_conservation.png',
        isVerified: true,
      ),
      EcoTravelSuggestion(
        key: 'local_guide_marrakech',
        title: 'Hire Local Guides in Marrakech',
        description: 'Support the local economy and get authentic experiences by hiring local guides who can show you the real Marrakech while sharing cultural insights.',
        category: 'Local Experiences',
        location: 'Marrakech, Morocco',
        carbonImpact: 0.1,
        carbonUnit: 'kg CO2/tour',
        benefits: [
          'Supports local economy',
          'Authentic cultural experience',
          'Better understanding of local life',
          'Access to hidden gems',
          'Cultural exchange opportunities'
        ],
        tips: [
          'Book through reputable agencies',
          'Learn basic Arabic phrases',
          'Respect local customs',
          'Support local businesses',
          'Ask about sustainable practices'
        ],
        imageUrl: 'assets/icons/local_guide.png',
        isVerified: true,
      ),
      EcoTravelSuggestion(
        key: 'train_travel_europe',
        title: 'Interrail Pass for Europe',
        description: 'Explore Europe sustainably with an Interrail pass, which allows unlimited train travel across multiple countries while reducing your carbon footprint significantly.',
        category: 'Transportation',
        location: 'Europe',
        carbonImpact: 0.041,
        carbonUnit: 'kg CO2/km',
        benefits: [
          'Significantly lower emissions than flying',
          'Scenic travel experience',
          'Flexible travel schedule',
          'Access to city centers',
          'Cost-effective for multiple countries'
        ],
        tips: [
          'Plan your route in advance',
          'Book popular routes early',
          'Use night trains to save time',
          'Pack light for easy travel',
          'Download offline maps'
        ],
        imageUrl: 'assets/icons/train_europe.png',
        isVerified: true,
      ),
      EcoTravelSuggestion(
        key: 'solar_powered_safari',
        title: 'Solar-Powered Safari Lodges',
        description: 'Experience African wildlife while staying at solar-powered safari lodges that minimize environmental impact and support conservation efforts.',
        category: 'Accommodation',
        location: 'Kenya, Tanzania, South Africa',
        carbonImpact: -3.0,
        carbonUnit: 'kg CO2/night',
        benefits: [
          'Supports wildlife conservation',
          'Renewable energy usage',
          'Authentic safari experience',
          'Educational about sustainability',
          'Supports local communities'
        ],
        tips: [
          'Choose certified eco-lodges',
          'Follow wildlife viewing guidelines',
          'Support conservation programs',
          'Learn about local ecosystems',
          'Respect wildlife and habitats'
        ],
        imageUrl: 'assets/icons/solar_safari.png',
        isVerified: true,
      ),
      EcoTravelSuggestion(
        key: 'zero_waste_markets',
        title: 'Visit Zero-Waste Markets',
        description: 'Explore zero-waste markets around the world where you can shop for local products without packaging, reducing waste and supporting sustainable practices.',
        category: 'Shopping',
        location: 'Global',
        carbonImpact: 0.2,
        carbonUnit: 'kg CO2/visit',
        benefits: [
          'Eliminates packaging waste',
          'Supports local producers',
          'Fresh, local products',
          'Educational about waste reduction',
          'Community building'
        ],
        tips: [
          'Bring your own containers',
          'Learn about local products',
          'Support small vendors',
          'Ask about sourcing practices',
          'Share the experience with others'
        ],
        imageUrl: 'assets/icons/zero_waste_market.png',
        isVerified: true,
      ),
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