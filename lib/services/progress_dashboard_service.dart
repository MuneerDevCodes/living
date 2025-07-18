// ProgressDashboardService.dart
import '../models/progress_dashboard_model.dart';
import 'carbon_footprint_dao.dart';
import 'waste_tracker_dao.dart';
import 'challenge_dao.dart';

class ProgressDashboardService {
  /// Aggregates user progress from multiple sources (carbon, waste, challenges, etc.)
  Future<UserProgress> getAggregatedProgress(String userId) async {
    // Fetch carbon footprint entries
    final carbonEntries = await CarbonFootprintDAO.getUserEntries(userId);
    final totalCarbon = carbonEntries.fold(0.0, (sum, e) => sum + e.carbonImpact);
    // Fetch waste entries
    final wasteEntries = await WasteTrackerDAO.getUserWasteEntries(userId);
    final totalWaste = wasteEntries.fold(0.0, (sum, e) => sum + e.amount);
    // Fetch completed challenges
    final userChallenges = await ChallengeDAO.getUserChallenges(userId);
    final completedChallenges = userChallenges.where((c) => c.isCompleted).length;
    // Aggregate category progress (carbon)
    final Map<String, double> categoryProgress = {};
    for (final entry in carbonEntries) {
      categoryProgress[entry.category] =
          (categoryProgress[entry.category] ?? 0) + entry.carbonImpact;
    }
    // Calculate total points (example: 10 points per completed challenge)
    final totalPoints = completedChallenges * 10;
    return UserProgress(
      key: '',
      userId: userId,
      date: DateTime.now(),
      carbonFootprint: totalCarbon,
      wasteReduction: totalWaste,
      energySavings: 0.0, // Could be calculated from energy entries
      challengesCompleted: completedChallenges,
      totalPoints: totalPoints,
      categoryProgress: categoryProgress,
    );
  }
} 