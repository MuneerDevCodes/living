import 'package:firebase_database/firebase_database.dart';
import 'package:living/models/carbon_footprint_model.dart';

class CarbonFootprintDAO {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref().child('carbon_footprint');
  static final DatabaseReference _goalsDatabase = FirebaseDatabase.instance.ref().child('carbon_goals');

  // Enhanced emission factors based on scientific research
  static final List<ActivityType> comprehensiveActivityTypes = [
    // Transportation
    ActivityType(
      name: 'Car Travel (Gasoline)',
      category: 'Transportation',
      subcategory: 'Personal Vehicle',
      carbonFactor: 0.404,
      unit: 'km',
      description: 'Average gasoline car emissions',
      icon: '🚗',
      tips: ['Carpool when possible', 'Maintain your vehicle', 'Consider electric vehicles'],
      source: 'EPA',
    ),
    ActivityType(
      name: 'Car Travel (Electric)',
      category: 'Transportation',
      subcategory: 'Personal Vehicle',
      carbonFactor: 0.092,
      unit: 'km',
      description: 'Electric vehicle emissions (grid average)',
      icon: '⚡',
      tips: ['Charge during off-peak hours', 'Use renewable energy sources'],
      source: 'EPA',
    ),
    ActivityType(
      name: 'Bus Travel',
      category: 'Transportation',
      subcategory: 'Public Transit',
      carbonFactor: 0.105,
      unit: 'km',
      description: 'Average bus emissions per passenger',
      icon: '🚌',
      tips: ['Use public transportation regularly', 'Support transit expansion'],
      source: 'EPA',
    ),
    ActivityType(
      name: 'Train Travel',
      category: 'Transportation',
      subcategory: 'Public Transit',
      carbonFactor: 0.041,
      unit: 'km',
      description: 'Average train emissions per passenger',
      icon: '🚆',
      tips: ['Choose trains over planes for short trips'],
      source: 'EPA',
    ),
    ActivityType(
      name: 'Air Travel (Domestic)',
      category: 'Transportation',
      subcategory: 'Air Travel',
      carbonFactor: 0.255,
      unit: 'km',
      description: 'Domestic flight emissions per passenger',
      icon: '✈️',
      tips: ['Consider video conferencing', 'Choose direct flights', 'Offset your emissions'],
      source: 'ICAO',
    ),
    ActivityType(
      name: 'Walking/Cycling',
      category: 'Transportation',
      subcategory: 'Active Transport',
      carbonFactor: 0.0,
      unit: 'km',
      description: 'Zero emissions transport',
      icon: '🚶',
      tips: ['Walk or cycle for short trips', 'Improve your health and the environment'],
      source: 'Zero Emissions',
    ),

    // Energy
    ActivityType(
      name: 'Electricity Usage',
      category: 'Energy',
      subcategory: 'Home Energy',
      carbonFactor: 0.92,
      unit: 'kWh',
      description: 'Grid electricity consumption',
      icon: '💡',
      tips: ['Switch to LED bulbs', 'Unplug unused devices', 'Use energy-efficient appliances'],
      source: 'EPA',
    ),
    ActivityType(
      name: 'Natural Gas',
      category: 'Energy',
      subcategory: 'Home Energy',
      carbonFactor: 2.02,
      unit: 'm³',
      description: 'Natural gas consumption',
      icon: '🔥',
      tips: ['Improve home insulation', 'Use programmable thermostats'],
      source: 'EPA',
    ),
    ActivityType(
      name: 'Heating Oil',
      category: 'Energy',
      subcategory: 'Home Energy',
      carbonFactor: 2.68,
      unit: 'L',
      description: 'Heating oil consumption',
      icon: '🛢️',
      tips: ['Consider heat pumps', 'Improve insulation'],
      source: 'EPA',
    ),
    ActivityType(
      name: 'Solar Energy',
      category: 'Energy',
      subcategory: 'Renewable Energy',
      carbonFactor: 0.0,
      unit: 'kWh',
      description: 'Solar power generation',
      icon: '☀️',
      tips: ['Install solar panels', 'Support renewable energy programs'],
      source: 'Zero Emissions',
    ),

    // Food
    ActivityType(
      name: 'Beef Consumption',
      category: 'Food',
      subcategory: 'Animal Products',
      carbonFactor: 13.3,
      unit: 'kg',
      description: 'Beef production emissions',
      icon: '🥩',
      tips: ['Reduce beef consumption', 'Choose plant-based alternatives'],
      source: 'FAO',
    ),
    ActivityType(
      name: 'Pork Consumption',
      category: 'Food',
      subcategory: 'Animal Products',
      carbonFactor: 4.6,
      unit: 'kg',
      description: 'Pork production emissions',
      icon: '🥓',
      tips: ['Reduce meat consumption', 'Choose local sources'],
      source: 'FAO',
    ),
    ActivityType(
      name: 'Chicken Consumption',
      category: 'Food',
      subcategory: 'Animal Products',
      carbonFactor: 2.9,
      unit: 'kg',
      description: 'Chicken production emissions',
      icon: '🍗',
      tips: ['Choose chicken over beef', 'Support free-range farming'],
      source: 'FAO',
    ),
    ActivityType(
      name: 'Dairy Products',
      category: 'Food',
      subcategory: 'Animal Products',
      carbonFactor: 1.4,
      unit: 'kg',
      description: 'Dairy production emissions',
      icon: '🥛',
      tips: ['Choose plant-based milk', 'Reduce dairy consumption'],
      source: 'FAO',
    ),
    ActivityType(
      name: 'Vegetables',
      category: 'Food',
      subcategory: 'Plant-Based',
      carbonFactor: 0.2,
      unit: 'kg',
      description: 'Vegetable production emissions',
      icon: '🥬',
      tips: ['Eat seasonal vegetables', 'Support local farmers'],
      source: 'FAO',
    ),
    ActivityType(
      name: 'Fruits',
      category: 'Food',
      subcategory: 'Plant-Based',
      carbonFactor: 0.3,
      unit: 'kg',
      description: 'Fruit production emissions',
      icon: '🍎',
      tips: ['Choose local fruits', 'Avoid air-freighted produce'],
      source: 'FAO',
    ),
    ActivityType(
      name: 'Grains',
      category: 'Food',
      subcategory: 'Plant-Based',
      carbonFactor: 0.5,
      unit: 'kg',
      description: 'Grain production emissions',
      icon: '🌾',
      tips: ['Choose whole grains', 'Support sustainable farming'],
      source: 'FAO',
    ),

    // Waste
    ActivityType(
      name: 'General Waste',
      category: 'Waste',
      subcategory: 'Landfill',
      carbonFactor: 0.5,
      unit: 'kg',
      description: 'Landfill waste emissions',
      icon: '🗑️',
      tips: ['Reduce waste', 'Recycle properly', 'Compost organic waste'],
      source: 'EPA',
    ),
    ActivityType(
      name: 'Recycled Materials',
      category: 'Waste',
      subcategory: 'Recycling',
      carbonFactor: -0.3,
      unit: 'kg',
      description: 'Carbon saved through recycling',
      icon: '♻️',
      tips: ['Recycle paper, plastic, metal', 'Buy recycled products'],
      source: 'EPA',
    ),
    ActivityType(
      name: 'Composting',
      category: 'Waste',
      subcategory: 'Organic Waste',
      carbonFactor: -0.2,
      unit: 'kg',
      description: 'Carbon saved through composting',
      icon: '🌱',
      tips: ['Compost food scraps', 'Use compost in your garden'],
      source: 'EPA',
    ),

    // Water
    ActivityType(
      name: 'Hot Water Usage',
      category: 'Water',
      subcategory: 'Home Water',
      carbonFactor: 0.298,
      unit: 'L',
      description: 'Hot water heating emissions',
      icon: '🚿',
      tips: ['Take shorter showers', 'Use cold water when possible'],
      source: 'EPA',
    ),
    ActivityType(
      name: 'Bottled Water',
      category: 'Water',
      subcategory: 'Packaged Water',
      carbonFactor: 0.298,
      unit: 'L',
      description: 'Bottled water production and transport',
      icon: '💧',
      tips: ['Use reusable water bottles', 'Install water filters'],
      source: 'EPA',
    ),

    // Digital
    ActivityType(
      name: 'Internet Usage',
      category: 'Digital',
      subcategory: 'Online Activities',
      carbonFactor: 0.0001,
      unit: 'GB',
      description: 'Data center and network emissions',
      icon: '🌐',
      tips: ['Stream in lower quality', 'Delete unnecessary files'],
      source: 'Greenpeace',
    ),
    ActivityType(
      name: 'Video Streaming',
      category: 'Digital',
      subcategory: 'Online Activities',
      carbonFactor: 0.0004,
      unit: 'hour',
      description: 'Video streaming emissions',
      icon: '📺',
      tips: ['Watch in lower resolution', 'Use audio-only when possible'],
      source: 'Greenpeace',
    ),
  ];

  // Get all entries for a user
  static Future<List<CarbonFootprintEntry>> getUserEntries(String userId) async {
    try {
      final snapshot = await _database.orderByChild('userId').equalTo(userId).get();
      List<CarbonFootprintEntry> entries = [];
      
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          entries.add(CarbonFootprintEntry.fromJson(child.key!, Map<String, dynamic>.from(child.value as Map)));
        }
      }
      
      return entries;
    } catch (e) {
      throw Exception('Failed to fetch carbon footprint entries: $e');
    }
  }

  // Add new entry
  static Future<void> addEntry(CarbonFootprintEntry entry) async {
    try {
      await _database.push().set(entry.toJson());
    } catch (e) {
      throw Exception('Failed to add carbon footprint entry: $e');
    }
  }

  // Update entry
  static Future<void> updateEntry(CarbonFootprintEntry entry) async {
    try {
      await _database.child(entry.key).update(entry.toJson());
    } catch (e) {
      throw Exception('Failed to update carbon footprint entry: $e');
    }
  }

  // Delete entry
  static Future<void> deleteEntry(String key) async {
    try {
      await _database.child(key).remove();
    } catch (e) {
      throw Exception('Failed to delete carbon footprint entry: $e');
    }
  }

  // Get entries by date range
  static Future<List<CarbonFootprintEntry>> getEntriesByDateRange(String userId, DateTime startDate, DateTime endDate) async {
    try {
      final entries = await getUserEntries(userId);
      return entries.where((entry) => 
        entry.date.isAfter(startDate.subtract(const Duration(days: 1))) && 
        entry.date.isBefore(endDate.add(const Duration(days: 1)))
      ).toList();
    } catch (e) {
      throw Exception('Failed to fetch entries by date range: $e');
    }
  }

  // Calculate carbon impact for an activity
  static double calculateCarbonImpact(String activityType, double value) {
    final activity = comprehensiveActivityTypes.firstWhere(
      (activity) => activity.name == activityType,
      orElse: () => comprehensiveActivityTypes.first,
    );
    return activity.carbonFactor * value;
  }

  // Get analytics for a user
  static Future<CarbonAnalytics> getUserAnalytics(String userId) async {
    try {
      final entries = await getUserEntries(userId);
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final monthAgo = now.subtract(const Duration(days: 30));
      final yearAgo = now.subtract(const Duration(days: 365));

      final weeklyEntries = entries.where((e) => e.date.isAfter(weekAgo)).toList();
      final monthlyEntries = entries.where((e) => e.date.isAfter(monthAgo)).toList();
      final yearlyEntries = entries.where((e) => e.date.isAfter(yearAgo)).toList();

      final totalFootprint = entries.fold(0.0, (sum, e) => sum + e.carbonImpact);
      final weeklyAverage = weeklyEntries.isEmpty ? 0.0 : weeklyEntries.fold(0.0, (sum, e) => sum + e.carbonImpact) / 7;
      final monthlyAverage = monthlyEntries.isEmpty ? 0.0 : monthlyEntries.fold(0.0, (sum, e) => sum + e.carbonImpact) / 30;
      final yearlyAverage = yearlyEntries.isEmpty ? 0.0 : yearlyEntries.fold(0.0, (sum, e) => sum + e.carbonImpact) / 365;

      // Category breakdown
      final categoryBreakdown = <String, double>{};
      for (final entry in entries) {
        categoryBreakdown[entry.category] = (categoryBreakdown[entry.category] ?? 0) + entry.carbonImpact;
      }

      // Weekly trend (last 4 weeks)
      final weeklyTrend = <String, double>{};
      for (int i = 0; i < 4; i++) {
        final weekStart = now.subtract(Duration(days: 7 * (i + 1)));
        final weekEnd = now.subtract(Duration(days: 7 * i));
        final weekEntries = entries.where((e) => 
          e.date.isAfter(weekStart) && e.date.isBefore(weekEnd)
        ).toList();
        final weekTotal = weekEntries.fold(0.0, (sum, e) => sum + e.carbonImpact);
        weeklyTrend['Week ${4 - i}'] = weekTotal;
      }

      // Monthly trend (last 6 months)
      final monthlyTrend = <String, double>{};
      for (int i = 0; i < 6; i++) {
        final monthStart = DateTime(now.year, now.month - i, 1);
        final monthEnd = DateTime(now.year, now.month - i + 1, 1);
        final monthEntries = entries.where((e) => 
          e.date.isAfter(monthStart) && e.date.isBefore(monthEnd)
        ).toList();
        final monthTotal = monthEntries.fold(0.0, (sum, e) => sum + e.carbonImpact);
        monthlyTrend['Month ${6 - i}'] = monthTotal;
      }

      // Calculate reduction percentage (assuming target is 5 kg CO2/day)
      const targetFootprint = 5.0;
      final reductionPercentage = ((targetFootprint - weeklyAverage) / targetFootprint) * 100;

      // Determine rank based on weekly average
      String rank;
      if (weeklyAverage <= 3.0) rank = 'Carbon Hero';
      else if (weeklyAverage <= 5.0) rank = 'Eco Warrior';
      else if (weeklyAverage <= 8.0) rank = 'Climate Conscious';
      else if (weeklyAverage <= 12.0) rank = 'Getting There';
      else rank = 'Room for Improvement';

      return CarbonAnalytics(
        totalFootprint: totalFootprint,
        weeklyAverage: weeklyAverage,
        monthlyAverage: monthlyAverage,
        yearlyAverage: yearlyAverage,
        categoryBreakdown: categoryBreakdown,
        weeklyTrend: weeklyTrend,
        monthlyTrend: monthlyTrend,
        reductionPercentage: reductionPercentage,
        targetFootprint: targetFootprint,
        rank: rank,
        totalEntries: entries.length,
      );
    } catch (e) {
      throw Exception('Failed to calculate analytics: $e');
    }
  }

  // Goal management
  static Future<List<CarbonGoal>> getUserGoals(String userId) async {
    try {
      final snapshot = await _goalsDatabase.orderByChild('userId').equalTo(userId).get();
      List<CarbonGoal> goals = [];
      
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          goals.add(CarbonGoal.fromJson(child.key!, Map<String, dynamic>.from(child.value as Map)));
        }
      }
      
      return goals;
    } catch (e) {
      throw Exception('Failed to fetch carbon goals: $e');
    }
  }

  static Future<void> addGoal(CarbonGoal goal) async {
    try {
      await _goalsDatabase.push().set(goal.toJson());
    } catch (e) {
      throw Exception('Failed to add carbon goal: $e');
    }
  }

  static Future<void> updateGoal(CarbonGoal goal) async {
    try {
      await _goalsDatabase.child(goal.key).update(goal.toJson());
    } catch (e) {
      throw Exception('Failed to update carbon goal: $e');
    }
  }

  static Future<void> deleteGoal(String key) async {
    try {
      await _goalsDatabase.child(key).remove();
    } catch (e) {
      throw Exception('Failed to delete carbon goal: $e');
    }
  }

  // Get activity types by category
  static List<ActivityType> getActivityTypesByCategory(String category) {
    return comprehensiveActivityTypes.where((activity) => activity.category == category).toList();
  }

  // Get all categories
  static List<String> getAllCategories() {
    return comprehensiveActivityTypes.map((activity) => activity.category).toSet().toList();
  }

  // Get subcategories for a category
  static List<String> getSubcategoriesForCategory(String category) {
    return comprehensiveActivityTypes
        .where((activity) => activity.category == category)
        .map((activity) => activity.subcategory)
        .toSet()
        .toList();
  }

  // Get activity by name
  static ActivityType? getActivityByName(String name) {
    try {
      return comprehensiveActivityTypes.firstWhere((activity) => activity.name == name);
    } catch (e) {
      return null;
    }
  }

  // Get tips for reducing carbon footprint
  static List<String> getGeneralTips() {
    return [
      'Use public transportation or carpool',
      'Switch to energy-efficient appliances',
      'Reduce meat consumption',
      'Recycle and compost waste',
      'Use renewable energy sources',
      'Take shorter showers',
      'Use reusable water bottles',
      'Stream in lower resolution',
      'Support local farmers',
      'Install LED bulbs',
      'Use programmable thermostats',
      'Choose direct flights',
      'Offset your emissions',
      'Walk or cycle for short trips',
      'Buy second-hand items',
    ];
  }
} 