import 'package:firebase_database/firebase_database.dart';
import 'package:living/models/carbon_footprint_model.dart';

class CarbonFootprintDAO {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref().child('carbon_footprint');

  // Get all entries for a user
  static Future<List<CarbonFootprintEntry>> getUserEntries(String userId) async {
    try {
      final snapshot = await _database.orderByChild('userId').equalTo(userId).get();
      List<CarbonFootprintEntry> entries = [];
      
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          entries.add(CarbonFootprintEntry.fromJson(child.key!, child.value as Map<String, dynamic>));
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
} 