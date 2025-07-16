import 'package:firebase_database/firebase_database.dart';
import 'package:living/models/certification_model.dart';

class CertificationDAO {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref().child('certifications');

  // Get all certifications
  static Future<List<Certification>> getAllCertifications() async {
    try {
      final snapshot = await _database.get();
      List<Certification> certifications = [];
      
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final value = child.value;
          if (value is Map) {
            // Convert LinkedMap<Object?, Object?> to Map<String, dynamic>
            final Map<String, dynamic> data = Map<String, dynamic>.from(value);
            certifications.add(Certification.fromJson(child.key!, data));
          }
        }
      }
      
      return certifications;
    } catch (e) {
      throw Exception('Failed to fetch certifications: $e');
    }
  }

  // Get certifications by category
  static Future<List<Certification>> getCertificationsByCategory(String category) async {
    try {
      final snapshot = await _database.orderByChild('category').equalTo(category).get();
      List<Certification> certifications = [];
      
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final value = child.value;
          if (value is Map) {
            // Convert LinkedMap<Object?, Object?> to Map<String, dynamic>
            final Map<String, dynamic> data = Map<String, dynamic>.from(value);
            certifications.add(Certification.fromJson(child.key!, data));
          }
        }
      }
      
      return certifications;
    } catch (e) {
      throw Exception('Failed to fetch certifications by category: $e');
    }
  }

  // Add new certification (admin only)
  static Future<void> addCertification(Certification certification) async {
    try {
      await _database.push().set(certification.toJson());
    } catch (e) {
      throw Exception('Failed to add certification: $e');
    }
  }

  // Update certification (admin only)
  static Future<void> updateCertification(Certification certification) async {
    try {
      await _database.child(certification.key).update(certification.toJson());
    } catch (e) {
      throw Exception('Failed to update certification: $e');
    }
  }

  // Delete certification (admin only)
  static Future<void> deleteCertification(String key) async {
    try {
      await _database.child(key).remove();
    } catch (e) {
      throw Exception('Failed to delete certification: $e');
    }
  }
} 