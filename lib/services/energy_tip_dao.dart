import 'package:firebase_database/firebase_database.dart';
import 'package:living/models/energy_tip_model.dart';

class EnergyTipDAO {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref().child('energy_tips');

  // Get all energy tips
  static Future<List<EnergyTip>> getAllEnergyTips() async {
    try {
      final snapshot = await _database.get();
      List<EnergyTip> tips = [];
      
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final value = child.value;
          if (value is Map) {
            final Map<String, dynamic> data = Map<String, dynamic>.from(value);
            tips.add(EnergyTip.fromJson(child.key!, data));
          }
        }
      }
      
      return tips;
    } catch (e) {
      throw Exception('Failed to fetch energy tips: $e');
    }
  }

  // Get energy tips by category
  static Future<List<EnergyTip>> getEnergyTipsByCategory(String category) async {
    try {
      final snapshot = await _database.orderByChild('category').equalTo(category).get();
      List<EnergyTip> tips = [];
      
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final value = child.value;
          if (value is Map) {
            final Map<String, dynamic> data = Map<String, dynamic>.from(value);
            tips.add(EnergyTip.fromJson(child.key!, data));
          }
        }
      }
      
      return tips;
    } catch (e) {
      throw Exception('Failed to fetch energy tips by category: $e');
    }
  }

  // Get energy tips by difficulty
  static Future<List<EnergyTip>> getEnergyTipsByDifficulty(String difficulty) async {
    try {
      final snapshot = await _database.orderByChild('difficulty').equalTo(difficulty).get();
      List<EnergyTip> tips = [];
      
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final value = child.value;
          if (value is Map) {
            final Map<String, dynamic> data = Map<String, dynamic>.from(value);
            tips.add(EnergyTip.fromJson(child.key!, data));
          }
        }
      }
      
      return tips;
    } catch (e) {
      throw Exception('Failed to fetch energy tips by difficulty: $e');
    }
  }

  // Add new energy tip (admin only)
  static Future<void> addEnergyTip(EnergyTip tip) async {
    try {
      await _database.push().set(tip.toJson());
    } catch (e) {
      throw Exception('Failed to add energy tip: $e');
    }
  }

  // Update energy tip (admin only)
  static Future<void> updateEnergyTip(EnergyTip tip) async {
    try {
      await _database.child(tip.key).update(tip.toJson());
    } catch (e) {
      throw Exception('Failed to update energy tip: $e');
    }
  }

  // Delete energy tip (admin only)
  static Future<void> deleteEnergyTip(String key) async {
    try {
      await _database.child(key).remove();
    } catch (e) {
      throw Exception('Failed to delete energy tip: $e');
    }
  }
} 