import 'package:living/models/carbon_footprint_model.dart';
import 'package:living/services/carbon_footprint_dao.dart';
import 'package:living/services/carbon_calculator_service.dart';

class CarbonInsightsService {
  // Achievement system
  static final List<CarbonAchievement> achievements = [
    CarbonAchievement(
      id: 'first_entry',
      title: 'First Steps',
      description: 'Log your first carbon activity',
      icon: '🌱',
      points: 10,
      requirement: 1,
      type: 'entries',
    ),
    CarbonAchievement(
      id: 'week_streak',
      title: 'Weekly Warrior',
      description: 'Log activities for 7 consecutive days',
      icon: '🔥',
      points: 50,
      requirement: 7,
      type: 'streak',
    ),
    CarbonAchievement(
      id: 'month_streak',
      title: 'Monthly Master',
      description: 'Log activities for 30 consecutive days',
      icon: '🏆',
      points: 200,
      requirement: 30,
      type: 'streak',
    ),
    CarbonAchievement(
      id: 'low_footprint',
      title: 'Eco Hero',
      description: 'Maintain daily footprint below 3 kg CO2 for a week',
      icon: '🌍',
      points: 100,
      requirement: 3,
      type: 'footprint',
    ),
    CarbonAchievement(
      id: 'category_explorer',
      title: 'Category Explorer',
      description: 'Log activities in all 6 categories',
      icon: '🗺️',
      points: 75,
      requirement: 6,
      type: 'categories',
    ),
    CarbonAchievement(
      id: 'goal_setter',
      title: 'Goal Setter',
      description: 'Set your first carbon reduction goal',
      icon: '🎯',
      points: 25,
      requirement: 1,
      type: 'goals',
    ),
    CarbonAchievement(
      id: 'goal_achiever',
      title: 'Goal Achiever',
      description: 'Complete your first carbon reduction goal',
      icon: '✅',
      points: 150,
      requirement: 1,
      type: 'completed_goals',
    ),
    CarbonAchievement(
      id: 'reduction_master',
      title: 'Reduction Master',
      description: 'Reduce your footprint by 50% compared to baseline',
      icon: '📉',
      points: 300,
      requirement: 50,
      type: 'reduction',
    ),
  ];

  // Get user insights
  static Future<CarbonInsights> getUserInsights(String userId) async {
    try {
      final entries = await CarbonFootprintDAO.getUserEntries(userId);
      final goals = await CarbonFootprintDAO.getUserGoals(userId);
      final analytics = await CarbonFootprintDAO.getUserAnalytics(userId);

      if (analytics == null) {
        return CarbonInsights(
          userId: userId,
          totalPoints: 0,
          level: 1,
          achievements: [],
          recommendations: [],
          insights: [],
          socialStats: CarbonSocialStats(
            totalEntries: 0,
            streakDays: 0,
            bestCategory: '',
            improvementPercentage: 0.0,
          ),
        );
      }

      final userAchievements = _calculateAchievements(entries, goals, analytics);
      final recommendations = _generateRecommendations(entries, analytics);
      final insights = _generateInsights(entries, analytics);
      final socialStats = _calculateSocialStats(entries, analytics);

      return CarbonInsights(
        userId: userId,
        totalPoints: userAchievements.fold(0, (sum, achievement) => sum + achievement.points),
        level: _calculateLevel(userAchievements),
        achievements: userAchievements,
        recommendations: recommendations,
        insights: insights,
        socialStats: socialStats,
      );
    } catch (e) {
      throw Exception('Failed to generate insights: $e');
    }
  }

  // Calculate user achievements
  static List<CarbonAchievement> _calculateAchievements(
    List<CarbonFootprintEntry> entries,
    List<CarbonGoal> goals,
    CarbonAnalytics analytics,
  ) {
    final userAchievements = <CarbonAchievement>[];

    // First entry achievement
    if (entries.isNotEmpty) {
      userAchievements.add(achievements.firstWhere((a) => a.id == 'first_entry'));
    }

    // Goal setter achievement
    if (goals.isNotEmpty) {
      userAchievements.add(achievements.firstWhere((a) => a.id == 'goal_setter'));
    }

    // Goal achiever achievement
    final completedGoals = goals.where((g) => g.status == 'completed').length;
    if (completedGoals >= 1) {
      userAchievements.add(achievements.firstWhere((a) => a.id == 'goal_achiever'));
    }

    // Category explorer achievement
    final categories = entries.map((e) => e.category).toSet().length;
    if (categories >= 6) {
      userAchievements.add(achievements.firstWhere((a) => a.id == 'category_explorer'));
    }

    // Low footprint achievement
    if (analytics.weeklyAverage <= 3.0) {
      userAchievements.add(achievements.firstWhere((a) => a.id == 'low_footprint'));
    }

    // Reduction master achievement
    if (analytics.reductionPercentage >= 50.0) {
      userAchievements.add(achievements.firstWhere((a) => a.id == 'reduction_master'));
    }

    return userAchievements;
  }

  // Generate personalized recommendations
  static List<CarbonRecommendation> _generateRecommendations(
    List<CarbonFootprintEntry> entries,
    CarbonAnalytics analytics,
  ) {
    final recommendations = <CarbonRecommendation>[];

    // Analyze transportation
    final transportEntries = entries.where((e) => e.category == 'Transportation').toList();
    if (transportEntries.isNotEmpty) {
      final avgTransport = transportEntries.fold(0.0, (sum, e) => sum + e.carbonImpact) / transportEntries.length;
      if (avgTransport > 5.0) {
        recommendations.add(CarbonRecommendation(
          category: 'Transportation',
          title: 'Consider Public Transit',
          description: 'Your transportation emissions are high. Try using public transportation or carpooling.',
          impact: 'High',
          difficulty: 'Medium',
          estimatedReduction: 2.0,
        ));
      }
    }

    // Analyze energy usage
    final energyEntries = entries.where((e) => e.category == 'Energy').toList();
    if (energyEntries.isNotEmpty) {
      final avgEnergy = energyEntries.fold(0.0, (sum, e) => sum + e.carbonImpact) / energyEntries.length;
      if (avgEnergy > 3.0) {
        recommendations.add(CarbonRecommendation(
          category: 'Energy',
          title: 'Switch to LED Bulbs',
          description: 'Replace traditional bulbs with LED lights to reduce electricity consumption.',
          impact: 'Medium',
          difficulty: 'Low',
          estimatedReduction: 0.5,
        ));
      }
    }

    // Analyze food consumption
    final foodEntries = entries.where((e) => e.category == 'Food').toList();
    final beefEntries = foodEntries.where((e) => e.activityType.contains('Beef')).toList();
    if (beefEntries.isNotEmpty) {
      recommendations.add(CarbonRecommendation(
        category: 'Food',
        title: 'Reduce Meat Consumption',
        description: 'Try meatless Mondays or switch to plant-based alternatives.',
        impact: 'High',
        difficulty: 'Medium',
        estimatedReduction: 1.5,
      ));
    }

    // General recommendations
    if (analytics.weeklyAverage > 8.0) {
      recommendations.add(CarbonRecommendation(
        category: 'General',
        title: 'Set Reduction Goals',
        description: 'Your footprint is above average. Set specific goals to reduce your impact.',
        impact: 'High',
        difficulty: 'Low',
        estimatedReduction: 2.0,
      ));
    }

    return recommendations;
  }

  // Generate insights
  static List<CarbonInsight> _generateInsights(
    List<CarbonFootprintEntry> entries,
    CarbonAnalytics analytics,
  ) {
    final insights = <CarbonInsight>[];

    if (entries.isEmpty) {
      insights.add(CarbonInsight(
        type: 'welcome',
        title: 'Welcome to Carbon Tracking!',
        message: 'Start by logging your first activity to see your carbon footprint.',
        icon: '🌱',
      ));
      return insights;
    }

    // Most active category
    final categoryCounts = <String, int>{};
    for (final entry in entries) {
      categoryCounts[entry.category] = (categoryCounts[entry.category] ?? 0) + 1;
    }
    final mostActiveCategory = categoryCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b).key;

    insights.add(CarbonInsight(
      type: 'category',
      title: 'Most Active Category',
      message: 'You log the most activities in $mostActiveCategory. Consider exploring other categories for a balanced footprint.',
      icon: '📊',
    ));

    // Footprint trend
    if (analytics.reductionPercentage > 0) {
      insights.add(CarbonInsight(
        type: 'improvement',
        title: 'Great Progress!',
        message: 'You\'ve reduced your footprint by ${analytics.reductionPercentage.toStringAsFixed(1)}%. Keep up the good work!',
        icon: '📈',
      ));
    } else if (analytics.reductionPercentage < 0) {
      insights.add(CarbonInsight(
        type: 'warning',
        title: 'Footprint Increased',
        message: 'Your footprint has increased by ${(-analytics.reductionPercentage).toStringAsFixed(1)}%. Consider setting reduction goals.',
        icon: '⚠️',
      ));
    }

    // Rank achievement
    insights.add(CarbonInsight(
      type: 'achievement',
      title: 'Your Rank: ${analytics.rank}',
      message: 'You\'re doing great! Your current rank reflects your commitment to sustainability.',
      icon: '🏆',
    ));

    return insights;
  }

  // Calculate social stats
  static CarbonSocialStats _calculateSocialStats(
    List<CarbonFootprintEntry> entries,
    CarbonAnalytics analytics,
  ) {
    if (entries.isEmpty) {
      return CarbonSocialStats(
        totalEntries: 0,
        streakDays: 0,
        bestCategory: '',
        improvementPercentage: 0.0,
      );
    }

    // Calculate streak
    int streakDays = 0;
    final now = DateTime.now();
    final sortedEntries = entries.toList()..sort((a, b) => b.date.compareTo(a.date));
    
    DateTime currentDate = now;
    for (final entry in sortedEntries) {
      if (entry.date.isAfter(currentDate.subtract(Duration(days: 1))) &&
          entry.date.isBefore(currentDate.add(Duration(days: 1)))) {
        streakDays++;
        currentDate = currentDate.subtract(Duration(days: 1));
      } else {
        break;
      }
    }

    // Find best category (lowest average footprint)
    final categoryAverages = <String, double>{};
    for (final entry in entries) {
      if (!categoryAverages.containsKey(entry.category)) {
        categoryAverages[entry.category] = 0.0;
      }
      categoryAverages[entry.category] = categoryAverages[entry.category]! + entry.carbonImpact;
    }

    String bestCategory = '';
    double lowestAverage = double.infinity;
    for (final entry in categoryAverages.entries) {
      final count = entries.where((e) => e.category == entry.key).length;
      final average = entry.value / count;
      if (average < lowestAverage) {
        lowestAverage = average;
        bestCategory = entry.key;
      }
    }

    return CarbonSocialStats(
      totalEntries: entries.length,
      streakDays: streakDays,
      bestCategory: bestCategory,
      improvementPercentage: analytics.reductionPercentage,
    );
  }

  // Calculate user level based on achievements
  static int _calculateLevel(List<CarbonAchievement> achievements) {
    final totalPoints = achievements.fold(0, (sum, achievement) => sum + achievement.points);
    
    if (totalPoints >= 1000) return 10;
    if (totalPoints >= 800) return 9;
    if (totalPoints >= 600) return 8;
    if (totalPoints >= 400) return 7;
    if (totalPoints >= 300) return 6;
    if (totalPoints >= 200) return 5;
    if (totalPoints >= 100) return 4;
    if (totalPoints >= 50) return 3;
    if (totalPoints >= 25) return 2;
    return 1;
  }

  // Get leaderboard data (mock data for now)
  static List<CarbonLeaderboardEntry> getLeaderboard() {
    return [
      CarbonLeaderboardEntry(
        userId: 'user1',
        username: 'EcoWarrior',
        level: 8,
        totalPoints: 750,
        weeklyAverage: 2.1,
        rank: 1,
      ),
      CarbonLeaderboardEntry(
        userId: 'user2',
        username: 'GreenThumb',
        level: 7,
        totalPoints: 650,
        weeklyAverage: 2.8,
        rank: 2,
      ),
      CarbonLeaderboardEntry(
        userId: 'user3',
        username: 'ClimateHero',
        level: 6,
        totalPoints: 550,
        weeklyAverage: 3.2,
        rank: 3,
      ),
      CarbonLeaderboardEntry(
        userId: 'user4',
        username: 'SustainableSoul',
        level: 5,
        totalPoints: 450,
        weeklyAverage: 3.5,
        rank: 4,
      ),
      CarbonLeaderboardEntry(
        userId: 'user5',
        username: 'EarthLover',
        level: 4,
        totalPoints: 350,
        weeklyAverage: 4.1,
        rank: 5,
      ),
    ];
  }

  // Get challenges
  static List<CarbonChallenge> getChallenges() {
    return [
      CarbonChallenge(
        id: 'transport_week',
        title: 'Transportation Week',
        description: 'Use only public transportation or active transport for 7 days',
        duration: 7,
        reward: 100,
        category: 'Transportation',
        difficulty: 'Medium',
      ),
      CarbonChallenge(
        id: 'meatless_week',
        title: 'Meatless Week',
        description: 'Go vegetarian for 7 days',
        duration: 7,
        reward: 75,
        category: 'Food',
        difficulty: 'Medium',
      ),
      CarbonChallenge(
        id: 'energy_saver',
        title: 'Energy Saver',
        description: 'Reduce electricity usage by 20% for a week',
        duration: 7,
        reward: 50,
        category: 'Energy',
        difficulty: 'Hard',
      ),
      CarbonChallenge(
        id: 'zero_waste',
        title: 'Zero Waste Week',
        description: 'Minimize waste and recycle everything for 7 days',
        duration: 7,
        reward: 80,
        category: 'Waste',
        difficulty: 'Hard',
      ),
    ];
  }
}

class CarbonAchievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int points;
  final int requirement;
  final String type;

  CarbonAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.points,
    required this.requirement,
    required this.type,
  });
}

class CarbonRecommendation {
  final String category;
  final String title;
  final String description;
  final String impact;
  final String difficulty;
  final double estimatedReduction;

  CarbonRecommendation({
    required this.category,
    required this.title,
    required this.description,
    required this.impact,
    required this.difficulty,
    required this.estimatedReduction,
  });
}

class CarbonInsight {
  final String type;
  final String title;
  final String message;
  final String icon;

  CarbonInsight({
    required this.type,
    required this.title,
    required this.message,
    required this.icon,
  });
}

class CarbonSocialStats {
  final int totalEntries;
  final int streakDays;
  final String bestCategory;
  final double improvementPercentage;

  CarbonSocialStats({
    required this.totalEntries,
    required this.streakDays,
    required this.bestCategory,
    required this.improvementPercentage,
  });
}

class CarbonInsights {
  final String userId;
  final int totalPoints;
  final int level;
  final List<CarbonAchievement> achievements;
  final List<CarbonRecommendation> recommendations;
  final List<CarbonInsight> insights;
  final CarbonSocialStats socialStats;

  CarbonInsights({
    required this.userId,
    required this.totalPoints,
    required this.level,
    required this.achievements,
    required this.recommendations,
    required this.insights,
    required this.socialStats,
  });
}

class CarbonLeaderboardEntry {
  final String userId;
  final String username;
  final int level;
  final int totalPoints;
  final double weeklyAverage;
  final int rank;

  CarbonLeaderboardEntry({
    required this.userId,
    required this.username,
    required this.level,
    required this.totalPoints,
    required this.weeklyAverage,
    required this.rank,
  });
}

class CarbonChallenge {
  final String id;
  final String title;
  final String description;
  final int duration;
  final int reward;
  final String category;
  final String difficulty;

  CarbonChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.reward,
    required this.category,
    required this.difficulty,
  });
} 