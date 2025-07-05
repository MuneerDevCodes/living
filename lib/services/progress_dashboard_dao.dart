import 'package:firebase_database/firebase_database.dart';
import 'package:living/models/progress_dashboard_model.dart';

class ProgressDashboardDAO {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref().child('user_progress');
  static final DatabaseReference _goalsDatabase = FirebaseDatabase.instance.ref().child('progress_goals');

  // Get user's progress
  static Future<List<UserProgress>> getUserProgress(String userId) async {
    try {
      final snapshot = await _database.orderByChild('userId').equalTo(userId).get();
      List<UserProgress> progress = [];
      
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          progress.add(UserProgress.fromJson(child.key!, child.value as Map<String, dynamic>));
        }
      }
      
      return progress;
    } catch (e) {
      throw Exception('Failed to fetch user progress: $e');
    }
  }

  // Add new progress entry
  static Future<void> addProgress(UserProgress progress) async {
    try {
      await _database.push().set(progress.toJson());
    } catch (e) {
      throw Exception('Failed to add progress: $e');
    }
  }

  // Update progress entry
  static Future<void> updateProgress(UserProgress progress) async {
    try {
      await _database.child(progress.key).update(progress.toJson());
    } catch (e) {
      throw Exception('Failed to update progress: $e');
    }
  }

  // Get user's progress goals
  static Future<List<ProgressGoal>> getUserGoals(String userId) async {
    try {
      final snapshot = await _goalsDatabase.orderByChild('userId').equalTo(userId).get();
      List<ProgressGoal> goals = [];
      
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          goals.add(ProgressGoal.fromJson(child.key!, child.value as Map<String, dynamic>));
        }
      }
      
      return goals;
    } catch (e) {
      throw Exception('Failed to fetch progress goals: $e');
    }
  }

  // Add new progress goal
  static Future<void> addProgressGoal(ProgressGoal goal) async {
    try {
      await _goalsDatabase.push().set(goal.toJson());
    } catch (e) {
      throw Exception('Failed to add progress goal: $e');
    }
  }

  // Update progress goal
  static Future<void> updateProgressGoal(ProgressGoal goal) async {
    try {
      await _goalsDatabase.child(goal.key).update(goal.toJson());
    } catch (e) {
      throw Exception('Failed to update progress goal: $e');
    }
  }

  // Delete progress goal
  static Future<void> deleteProgressGoal(String key) async {
    try {
      await _goalsDatabase.child(key).remove();
    } catch (e) {
      throw Exception('Failed to delete progress goal: $e');
    }
  }

  // Get progress by date range
  static Future<List<UserProgress>> getProgressByDateRange(String userId, DateTime startDate, DateTime endDate) async {
    try {
      final progress = await getUserProgress(userId);
      return progress.where((entry) => 
        entry.date.isAfter(startDate.subtract(const Duration(days: 1))) && 
        entry.date.isBefore(endDate.add(const Duration(days: 1)))
      ).toList();
    } catch (e) {
      throw Exception('Failed to fetch progress by date range: $e');
    }
  }
} 