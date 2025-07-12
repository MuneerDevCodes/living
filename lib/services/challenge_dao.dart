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
      
      return challenges;
    } catch (e) {
      throw Exception('Failed to fetch challenges: $e');
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