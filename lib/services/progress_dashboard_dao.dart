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
          try {
            // Convert LinkedMap to Map<String, dynamic> safely
            final Map<String, dynamic> jsonData = Map<String, dynamic>.from(child.value as Map);
            progress.add(UserProgress.fromJson(child.key!, jsonData));
          } catch (parseError) {
            print('Error parsing progress entry ${child.key}: $parseError');
            // Skip this entry and continue with others
            continue;
          }
        }
      }
      
      return progress;
    } catch (e) {
      print('Error fetching user progress: $e');
      // Return empty list instead of throwing exception
      return [];
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
          try {
            final value = Map<String, dynamic>.from(child.value as Map);
            goals.add(ProgressGoal.fromJson(child.key!, value));
          } catch (parseError) {
            print('Error parsing goal entry ${child.key}: $parseError');
            // Skip this entry and continue with others
            continue;
          }
        }
      }
      
      return goals;
    } catch (e) {
      print('Error fetching user goals: $e');
      // Return empty list instead of throwing exception
      return [];
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