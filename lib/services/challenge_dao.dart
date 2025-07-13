import 'package:firebase_database/firebase_database.dart';
import 'package:living/models/challenge_model.dart';

class ChallengeDAO {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref().child('challenges');
  static final DatabaseReference _userChallengesDatabase = FirebaseDatabase.instance.ref().child('user_challenges');

  // Get all active challenges
  static Future<List<Challenge>> getActiveChallenges() async {
    try {
      final snapshot = await _database.orderByChild('isActive').equalTo(true).get();
      List<Challenge> challenges = [];
      
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          challenges.add(Challenge.fromJson(child.key!, Map<String, dynamic>.from(child.value as Map)));
        }
      }
      
      // If no challenges exist, initialize sample challenges
      if (challenges.isEmpty) {
        await _initializeSampleChallenges();
        return await getActiveChallenges(); // Recursive call to get the initialized challenges
      }
      
      return challenges;
    } catch (e) {
      throw Exception('Failed to fetch challenges: $e');
    }
  }

  // Initialize sample challenges with meaningful content
  static Future<void> _initializeSampleChallenges() async {
    final sampleChallenges = [
      Challenge(
        key: 'energy_conservation_week',
        title: 'Energy Conservation Week',
        description: 'Reduce your household energy consumption by implementing simple but effective energy-saving practices. This challenge will help you understand your energy usage patterns and develop sustainable habits.',
        category: 'Energy Conservation',
        durationDays: 7,
        pointsReward: 150,
        difficulty: 'Medium',
        tasks: [
          'Turn off all lights when leaving a room',
          'Unplug electronics when not in use',
          'Use natural light during daytime',
          'Set thermostat 2°C lower in winter',
          'Wash clothes in cold water',
          'Use energy-efficient appliances',
          'Take shorter showers (5 minutes max)'
        ],
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        isActive: true,
        environmentalImpact: 'Reduces household energy consumption by 15-20%, decreasing carbon emissions from electricity generation.',
        benefits: 'Lower utility bills, reduced carbon footprint, increased energy awareness, and contribution to renewable energy transition.',
        tips: [
          'Use a smart power strip to easily turn off multiple devices',
          'Install LED bulbs for immediate energy savings',
          'Use a programmable thermostat for automatic temperature control',
          'Check your energy bill to track your progress'
        ],
        carbonReduction: 2.5, // kg CO2 per day
        icon: '⚡',
      ),
      Challenge(
        key: 'zero_waste_week',
        title: 'Zero Waste Week',
        description: 'Minimize your waste production and learn about sustainable waste management. This challenge will help you understand the impact of your consumption habits and develop eco-friendly alternatives.',
        category: 'Waste Reduction',
        durationDays: 7,
        pointsReward: 200,
        difficulty: 'Hard',
        tasks: [
          'Use reusable shopping bags',
          'Avoid single-use plastics',
          'Compost food scraps',
          'Recycle all recyclable materials',
          'Use refillable water bottle',
          'Buy products with minimal packaging',
          'Repair items instead of replacing'
        ],
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        isActive: true,
        environmentalImpact: 'Reduces landfill waste by up to 80%, decreases plastic pollution, and lowers methane emissions from waste decomposition.',
        benefits: 'Saves money on disposable items, reduces environmental pollution, supports circular economy, and creates healthier communities.',
        tips: [
          'Start with one room at a time',
          'Keep reusable items in your car or bag',
          'Find local bulk stores for package-free shopping',
          'Learn what can be composted in your area'
        ],
        carbonReduction: 3.2, // kg CO2 per day
        icon: '♻️',
      ),
      Challenge(
        key: 'sustainable_transport_week',
        title: 'Sustainable Transportation Week',
        description: 'Reduce your carbon footprint by choosing eco-friendly transportation options. This challenge will help you explore alternative transportation methods and their environmental benefits.',
        category: 'Transportation',
        durationDays: 7,
        pointsReward: 180,
        difficulty: 'Medium',
        tasks: [
          'Walk or bike for short trips',
          'Use public transportation',
          'Carpool with colleagues',
          'Combine errands to reduce trips',
          'Use electric or hybrid vehicles',
          'Plan efficient routes',
          'Support local businesses to reduce travel'
        ],
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        isActive: true,
        environmentalImpact: 'Reduces transportation emissions by 40-60%, decreases air pollution, and supports sustainable urban development.',
        benefits: 'Improves physical health, saves money on fuel and parking, reduces traffic congestion, and promotes community connections.',
        tips: [
          'Plan your week to minimize car trips',
          'Use apps to find public transit routes',
          'Consider carpooling apps for longer trips',
          'Invest in good walking shoes and weather gear'
        ],
        carbonReduction: 4.8, // kg CO2 per day
        icon: '🚲',
      ),
      Challenge(
        key: 'plant_based_week',
        title: 'Plant-Based Week',
        description: 'Explore the environmental impact of food choices by adopting a plant-based diet for a week. This challenge will help you understand the carbon footprint of different food choices.',
        category: 'Food & Diet',
        durationDays: 7,
        pointsReward: 120,
        difficulty: 'Easy',
        tasks: [
          'Replace meat with plant proteins',
          'Try new vegetarian recipes',
          'Buy local and seasonal produce',
          'Reduce food waste',
          'Use reusable food containers',
          'Support sustainable food brands',
          'Learn about food carbon footprint'
        ],
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        isActive: true,
        environmentalImpact: 'Reduces food-related carbon emissions by 50-70%, decreases water usage, and reduces deforestation for livestock.',
        benefits: 'Improves health, reduces grocery bills, supports sustainable agriculture, and decreases animal suffering.',
        tips: [
          'Start with familiar foods like pasta and rice dishes',
          'Try meat alternatives like tofu, tempeh, or seitan',
          'Plan meals ahead to avoid food waste',
          'Explore local farmers markets for fresh produce'
        ],
        carbonReduction: 2.1, // kg CO2 per day
        icon: '🥬',
      ),
      Challenge(
        key: 'water_conservation_week',
        title: 'Water Conservation Week',
        description: 'Learn to use water more efficiently and understand the importance of water conservation. This challenge will help you develop water-saving habits that benefit both the environment and your utility bills.',
        category: 'Water Conservation',
        durationDays: 7,
        pointsReward: 100,
        difficulty: 'Easy',
        tasks: [
          'Fix any water leaks',
          'Take shorter showers',
          'Turn off tap while brushing teeth',
          'Use water-efficient appliances',
          'Collect rainwater for plants',
          'Water plants in the morning',
          'Use full loads for laundry'
        ],
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        isActive: true,
        environmentalImpact: 'Reduces water consumption by 20-30%, decreases energy used for water treatment, and preserves freshwater ecosystems.',
        benefits: 'Lowers water bills, reduces energy costs, supports water security, and protects aquatic habitats.',
        tips: [
          'Install low-flow showerheads and faucets',
          'Use a shower timer to track water usage',
          'Check for leaks with food coloring in toilet tank',
          'Water plants deeply but less frequently'
        ],
        carbonReduction: 0.8, // kg CO2 per day
        icon: '💧',
      ),
      Challenge(
        key: 'digital_detox_week',
        title: 'Digital Detox Week',
        description: 'Reduce your digital carbon footprint by being more mindful of your technology usage. This challenge will help you understand the environmental impact of digital activities.',
        category: 'Energy Conservation',
        durationDays: 7,
        pointsReward: 80,
        difficulty: 'Medium',
        tasks: [
          'Reduce screen time by 50%',
          'Delete unnecessary files and emails',
          'Use energy-saving device settings',
          'Unplug devices when fully charged',
          'Stream videos in lower quality',
          'Use cloud storage efficiently',
          'Support renewable energy for data centers'
        ],
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        isActive: true,
        environmentalImpact: 'Reduces digital carbon footprint by 30-40%, decreases energy consumption from data centers, and supports renewable energy adoption.',
        benefits: 'Improves mental health, increases productivity, reduces eye strain, and saves money on electricity.',
        tips: [
          'Set screen time limits on your devices',
          'Use dark mode to save battery',
          'Delete old emails and files regularly',
          'Choose renewable energy providers'
        ],
        carbonReduction: 1.2, // kg CO2 per day
        icon: '📱',
      ),
      Challenge(
        key: 'local_living_week',
        title: 'Local Living Week',
        description: 'Support your local community and reduce transportation emissions by choosing local products and services. This challenge will help you discover local sustainable options.',
        category: 'Transportation',
        durationDays: 7,
        pointsReward: 90,
        difficulty: 'Easy',
        tasks: [
          'Shop at local farmers markets',
          'Support local businesses',
          'Use local services',
          'Attend local events',
          'Join community sustainability groups',
          'Share resources with neighbors',
          'Learn about local sustainability initiatives'
        ],
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        isActive: true,
        environmentalImpact: 'Reduces transportation emissions by 60-80%, supports local economies, and decreases packaging waste from long-distance shipping.',
        benefits: 'Strengthens community bonds, supports local jobs, reduces food miles, and often provides fresher, healthier products.',
        tips: [
          'Research local farmers markets and their schedules',
          'Join local community groups on social media',
          'Ask local businesses about their sustainability practices',
          'Start a neighborhood tool or book sharing program'
        ],
        carbonReduction: 1.8, // kg CO2 per day
        icon: '🏘️',
      ),
      Challenge(
        key: 'mindful_consumption_week',
        title: 'Mindful Consumption Week',
        description: 'Practice conscious consumption by making thoughtful purchasing decisions. This challenge will help you understand the environmental impact of your buying choices.',
        category: 'Waste Reduction',
        durationDays: 7,
        pointsReward: 110,
        difficulty: 'Medium',
        tasks: [
          'Buy only what you need',
          'Choose products with eco-certifications',
          'Support ethical and sustainable brands',
          'Avoid impulse purchases',
          'Research product sustainability',
          'Share or borrow items instead of buying',
          'Repair items before replacing'
        ],
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        isActive: true,
        environmentalImpact: 'Reduces resource extraction by 25-40%, decreases manufacturing emissions, and supports sustainable production practices.',
        benefits: 'Saves money, reduces clutter, supports ethical businesses, and creates more meaningful relationships with possessions.',
        tips: [
          'Wait 24 hours before making non-essential purchases',
          'Research brands\' sustainability practices',
          'Look for second-hand options first',
          'Learn basic repair skills for common items'
        ],
        carbonReduction: 1.5, // kg CO2 per day
        icon: '🛒',
      ),
    ];

    try {
      for (final challenge in sampleChallenges) {
        await _database.push().set(challenge.toJson());
      }
    } catch (e) {
      throw Exception('Failed to initialize sample challenges: $e');
    }
  }

  // Get user's active challenges
  static Future<List<UserChallenge>> getUserChallenges(String userId) async {
    try {
      final snapshot = await _userChallengesDatabase.orderByChild('userId').equalTo(userId).get();
      List<UserChallenge> userChallenges = [];
      
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          userChallenges.add(UserChallenge.fromJson(child.key!, Map<String, dynamic>.from(child.value as Map)));
        }
      }
      
      return userChallenges;
    } catch (e) {
      throw Exception('Failed to fetch user challenges: $e');
    }
  }

  // Start a challenge
  static Future<void> startChallenge(UserChallenge userChallenge) async {
    try {
      await _userChallengesDatabase.push().set(userChallenge.toJson());
    } catch (e) {
      throw Exception('Failed to start challenge: $e');
    }
  }

  // Update challenge progress
  static Future<void> updateChallengeProgress(UserChallenge userChallenge) async {
    try {
      await _userChallengesDatabase.child(userChallenge.key).update(userChallenge.toJson());
    } catch (e) {
      throw Exception('Failed to update challenge progress: $e');
    }
  }

  // Complete a challenge
  static Future<void> completeChallenge(String challengeKey) async {
    try {
      await _userChallengesDatabase.child(challengeKey).update({
        'isCompleted': true,
        'completedDate': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to complete challenge: $e');
    }
  }

  // Add new challenge (admin only)
  static Future<void> addChallenge(Challenge challenge) async {
    try {
      await _database.push().set(challenge.toJson());
    } catch (e) {
      throw Exception('Failed to add challenge: $e');
    }
  }

  // Update challenge (admin only)
  static Future<void> updateChallenge(Challenge challenge) async {
    try {
      await _database.child(challenge.key).update(challenge.toJson());
    } catch (e) {
      throw Exception('Failed to update challenge: $e');
    }
  }

  // Delete challenge (admin only)
  static Future<void> deleteChallenge(String key) async {
    try {
      await _database.child(key).remove();
    } catch (e) {
      throw Exception('Failed to delete challenge: $e');
    }
  }
} 