import 'package:firebase_database/firebase_database.dart';
import 'package:living/models/waste_tracker_model.dart';

class WasteTrackerDAO {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref().child('waste_entries');
  static final DatabaseReference _goalsDatabase = FirebaseDatabase.instance.ref().child('waste_goals');

  // Get all waste entries for a user
  static Future<List<WasteEntry>> getUserWasteEntries(String userId) async {
    try {
      final snapshot = await _database.orderByChild('userId').equalTo(userId).get();
      List<WasteEntry> entries = [];
      
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          entries.add(WasteEntry.fromJson(child.key!, child.value as Map<String, dynamic>));
        }
      }
      
      return entries;
    } catch (e) {
      throw Exception('Failed to fetch waste entries: $e');
    }
  }

  // Add new waste entry
  static Future<void> addWasteEntry(WasteEntry entry) async {
    try {
      await _database.push().set(entry.toJson());
    } catch (e) {
      throw Exception('Failed to add waste entry: $e');
    }
  }

  // Update waste entry
  static Future<void> updateWasteEntry(WasteEntry entry) async {
    try {
      await _database.child(entry.key).update(entry.toJson());
    } catch (e) {
      throw Exception('Failed to update waste entry: $e');
    }
  }

  // Delete waste entry
  static Future<void> deleteWasteEntry(String key) async {
    try {
      await _database.child(key).remove();
    } catch (e) {
      throw Exception('Failed to delete waste entry: $e');
    }
  }

  // Get user's waste reduction goals
  static Future<List<WasteReductionGoal>> getUserGoals(String userId) async {
    try {
      final snapshot = await _goalsDatabase.orderByChild('userId').equalTo(userId).get();
      List<WasteReductionGoal> goals = [];
      
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          goals.add(WasteReductionGoal.fromJson(child.key!, child.value as Map<String, dynamic>));
        }
      }
      
      return goals;
    } catch (e) {
      throw Exception('Failed to fetch waste goals: $e');
    }
  }

  // Add new waste reduction goal
  static Future<void> addWasteGoal(WasteReductionGoal goal) async {
    try {
      await _goalsDatabase.push().set(goal.toJson());
    } catch (e) {
      throw Exception('Failed to add waste goal: $e');
    }
  }

  // Update waste reduction goal
  static Future<void> updateWasteGoal(WasteReductionGoal goal) async {
    try {
      await _goalsDatabase.child(goal.key).update(goal.toJson());
    } catch (e) {
      throw Exception('Failed to update waste goal: $e');
    }
  }

  // Delete waste reduction goal
  static Future<void> deleteWasteGoal(String key) async {
    try {
      await _goalsDatabase.child(key).remove();
    } catch (e) {
      throw Exception('Failed to delete waste goal: $e');
    }
  }
} 