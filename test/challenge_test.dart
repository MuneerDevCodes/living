import 'package:flutter_test/flutter_test.dart';
import 'package:living/models/challenge_model.dart';

void main() {
  group('Challenge Model Tests', () {
    test('should create challenge with all properties', () {
      final challenge = Challenge(
        key: 'test_challenge',
        title: 'Test Challenge',
        description: 'A test challenge for sustainability',
        category: 'Energy Conservation',
        durationDays: 7,
        pointsReward: 100,
        difficulty: 'Medium',
        tasks: ['Task 1', 'Task 2', 'Task 3'],
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        isActive: true,
        environmentalImpact: 'Reduces energy consumption by 20%',
        benefits: 'Lower utility bills and reduced carbon footprint',
        tips: ['Tip 1', 'Tip 2'],
        carbonReduction: 2.5,
        icon: '⚡',
      );

      expect(challenge.key, 'test_challenge');
      expect(challenge.title, 'Test Challenge');
      expect(challenge.category, 'Energy Conservation');
      expect(challenge.durationDays, 7);
      expect(challenge.pointsReward, 100);
      expect(challenge.difficulty, 'Medium');
      expect(challenge.tasks.length, 3);
      expect(challenge.isActive, true);
      expect(challenge.environmentalImpact, 'Reduces energy consumption by 20%');
      expect(challenge.benefits, 'Lower utility bills and reduced carbon footprint');
      expect(challenge.tips.length, 2);
      expect(challenge.carbonReduction, 2.5);
      expect(challenge.icon, '⚡');
    });

    test('should convert challenge to JSON and back', () {
      final originalChallenge = Challenge(
        key: 'test_challenge',
        title: 'Test Challenge',
        description: 'A test challenge for sustainability',
        category: 'Energy Conservation',
        durationDays: 7,
        pointsReward: 100,
        difficulty: 'Medium',
        tasks: ['Task 1', 'Task 2', 'Task 3'],
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        isActive: true,
        environmentalImpact: 'Reduces energy consumption by 20%',
        benefits: 'Lower utility bills and reduced carbon footprint',
        tips: ['Tip 1', 'Tip 2'],
        carbonReduction: 2.5,
        icon: '⚡',
      );

      final json = originalChallenge.toJson();
      final convertedChallenge = Challenge.fromJson('test_challenge', json);

      expect(convertedChallenge.title, originalChallenge.title);
      expect(convertedChallenge.description, originalChallenge.description);
      expect(convertedChallenge.category, originalChallenge.category);
      expect(convertedChallenge.durationDays, originalChallenge.durationDays);
      expect(convertedChallenge.pointsReward, originalChallenge.pointsReward);
      expect(convertedChallenge.difficulty, originalChallenge.difficulty);
      expect(convertedChallenge.tasks, originalChallenge.tasks);
      expect(convertedChallenge.isActive, originalChallenge.isActive);
      expect(convertedChallenge.environmentalImpact, originalChallenge.environmentalImpact);
      expect(convertedChallenge.benefits, originalChallenge.benefits);
      expect(convertedChallenge.tips, originalChallenge.tips);
      expect(convertedChallenge.carbonReduction, originalChallenge.carbonReduction);
      expect(convertedChallenge.icon, originalChallenge.icon);
    });
  });

  group('UserChallenge Model Tests', () {
    test('should create user challenge with all properties', () {
      final userChallenge = UserChallenge(
        key: 'test_user_challenge',
        userId: 'user123',
        challengeId: 'challenge123',
        startDate: DateTime.now(),
        completedDate: null,
        isCompleted: false,
        progress: 0,
        taskCompletion: [false, false, false],
      );

      expect(userChallenge.key, 'test_user_challenge');
      expect(userChallenge.userId, 'user123');
      expect(userChallenge.challengeId, 'challenge123');
      expect(userChallenge.isCompleted, false);
      expect(userChallenge.progress, 0);
      expect(userChallenge.taskCompletion.length, 3);
      expect(userChallenge.completedDate, null);
    });

    test('should convert user challenge to JSON and back', () {
      final originalUserChallenge = UserChallenge(
        key: 'test_user_challenge',
        userId: 'user123',
        challengeId: 'challenge123',
        startDate: DateTime.now(),
        completedDate: null,
        isCompleted: false,
        progress: 0,
        taskCompletion: [false, false, false],
      );

      final json = originalUserChallenge.toJson();
      final convertedUserChallenge = UserChallenge.fromJson('test_user_challenge', json);

      expect(convertedUserChallenge.userId, originalUserChallenge.userId);
      expect(convertedUserChallenge.challengeId, originalUserChallenge.challengeId);
      expect(convertedUserChallenge.isCompleted, originalUserChallenge.isCompleted);
      expect(convertedUserChallenge.progress, originalUserChallenge.progress);
      expect(convertedUserChallenge.taskCompletion, originalUserChallenge.taskCompletion);
    });
  });
} 