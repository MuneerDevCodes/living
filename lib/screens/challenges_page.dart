import 'package:flutter/material.dart';
import 'package:living/models/challenge_model.dart';
import 'package:living/services/challenge_dao.dart';
import 'package:living/services/auth_helper.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/widgets/alert_error.dart';
import 'package:living/widgets/alert_success.dart';

class ChallengesPage extends StatefulWidget {
  const ChallengesPage({super.key});

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  List<Challenge> availableChallenges = [];
  List<UserChallenge> userChallenges = [];
  bool isLoading = true;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);
      userId = AuthService.getCurrentUserId();
      if (userId != null) {
        availableChallenges = await ChallengeDAO.getActiveChallenges();
        userChallenges = await ChallengeDAO.getUserChallenges(userId!);
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertError('Failed to load challenges: $e'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sustainable Challenges'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Available'),
              Tab(text: 'My Challenges'),
            ],
            indicatorColor: Colors.white,
          ),
        ),
        body: isLoading
            ? const Loader()
            : TabBarView(
                children: [
                  _buildAvailableChallenges(),
                  _buildUserChallenges(),
                ],
              ),
      ),
    );
  }

  Widget _buildAvailableChallenges() {
    if (availableChallenges.isEmpty) {
      return const Center(
        child: Text(
          'No challenges available at the moment.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: availableChallenges.length,
      itemBuilder: (context, index) {
        final challenge = availableChallenges[index];
        final isParticipating = userChallenges.any((uc) => uc.challengeId == challenge.key);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        challenge.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(challenge.difficulty),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        challenge.difficulty,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  challenge.description,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${challenge.durationDays} days',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.star, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${challenge.pointsReward} points',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!isParticipating)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _startChallenge(challenge),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Start Challenge', style: TextStyle(color: Colors.white)),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Already Participating',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserChallenges() {
    if (userChallenges.isEmpty) {
      return const Center(
        child: Text(
          'You haven\'t started any challenges yet.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: userChallenges.length,
      itemBuilder: (context, index) {
        final userChallenge = userChallenges[index];
        final challenge = availableChallenges.firstWhere(
          (c) => c.key == userChallenge.challengeId,
          orElse: () => Challenge(
            key: '',
            title: 'Unknown Challenge',
            description: '',
            category: '',
            durationDays: 0,
            pointsReward: 0,
            difficulty: '',
            tasks: [],
            startDate: DateTime.now(),
            endDate: DateTime.now(),
          ),
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: userChallenge.progress / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                ),
                const SizedBox(height: 8),
                Text(
                  '${userChallenge.progress}% Complete',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                if (!userChallenge.isCompleted)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _updateProgress(userChallenge),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      child: const Text('Update Progress', style: TextStyle(color: Colors.white)),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Completed!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _startChallenge(Challenge challenge) async {
    try {
      final userChallenge = UserChallenge(
        key: '',
        userId: userId!,
        challengeId: challenge.key,
        startDate: DateTime.now(),
        taskCompletion: List.filled(challenge.tasks.length, false),
      );

      await ChallengeDAO.startChallenge(userChallenge);
      _loadData();
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => const AlertSuccess('Challenge started successfully!'),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertError('Failed to start challenge: $e'),
        );
      }
    }
  }

  void _updateProgress(UserChallenge userChallenge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Progress'),
        content: const Text('Mark a task as completed to update your progress.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Simple progress update - in a real app, you'd show task list
              final newProgress = userChallenge.progress + 25;
              final updatedChallenge = UserChallenge(
                key: userChallenge.key,
                userId: userChallenge.userId,
                challengeId: userChallenge.challengeId,
                startDate: userChallenge.startDate,
                progress: newProgress > 100 ? 100 : newProgress,
                taskCompletion: userChallenge.taskCompletion,
                isCompleted: newProgress >= 100,
              );

              try {
                await ChallengeDAO.updateChallengeProgress(updatedChallenge);
                Navigator.pop(context);
                _loadData();
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => const AlertSuccess('Progress updated!'),
                  );
                }
              } catch (e) {
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertError('Failed to update progress: $e'),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
} 