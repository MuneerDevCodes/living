import 'package:flutter/material.dart';
import 'package:living/models/challenge_model.dart';
import 'package:living/services/challenge_dao.dart';
import 'package:living/services/auth_helper.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/widgets/alert_error.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';

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
  String selectedCategory = 'All';

  final List<String> categories = [
    'All',
    'Energy Conservation',
    'Waste Reduction',
    'Transportation',
    'Food & Diet',
    'Water Conservation',
  ];

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

  List<Challenge> get filteredChallenges {
    if (selectedCategory == 'All') {
      return availableChallenges;
    }
    return availableChallenges.where((challenge) => challenge.category == selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        drawer: Header.buildDrawer(context),
        body: Column(
          children: [
            const Header(),
            Expanded(
              child: Stack(
                children: [
                  if (isLoading) const Positioned.fill(child: Loader()),
                  Column(
                    children: [
                      Container(
                        color: AppColors.primary,
                        child: TabBar(
                          tabs: [
                            Tab(
                              child: Text(
                                'Active Challenges',
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                            Tab(
                              child: Text(
                                'My Progress',
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ],
                          indicatorColor: AppColors.white,
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildChallengesTab(),
                            _buildProgressTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Footer(),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengesTab() {
    return Column(
      children: [
        _buildCategoryFilter(),
        Expanded(
          child: _buildChallengesList(),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: ResponsiveHelper.getScreenHeight(context) * 0.08,
      padding: ResponsiveHelper.getVerticalPadding(context),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: ResponsiveHelper.getHorizontalPadding(context),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return Container(
            margin: EdgeInsets.only(right: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
            child: FilterChip(
              label: Text(
                category,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedCategory = category;
                });
              },
              selectedColor: AppColors.success,
              checkmarkColor: AppColors.white,
            ),
          );
        },
      ),
    );
  }

  Widget _buildChallengesList() {
    if (filteredChallenges.isEmpty) {
      return Center(
        child: Text(
          'No challenges found for this category.',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
            color: AppColors.secondaryText,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      itemCount: filteredChallenges.length,
      itemBuilder: (context, index) {
        final challenge = filteredChallenges[index];
        return _buildChallengeCard(challenge);
      },
    );
  }

  Widget _buildChallengeCard(Challenge challenge) {
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context)),
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getDifficultyColor(challenge.difficulty),
                  child: Text(
                    challenge.difficulty[0],
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.1),
                      Text(
                        challenge.description,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                          color: AppColors.secondaryText,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: ResponsiveHelper.getAdaptiveIconSize(context),
                  color: AppColors.secondaryText,
                ),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                Text(
                  '${challenge.durationDays} days',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                    color: AppColors.secondaryText,
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8),
                Icon(
                  Icons.star,
                  size: ResponsiveHelper.getAdaptiveIconSize(context),
                  color: AppColors.secondaryText,
                ),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                Text(
                  '${challenge.pointsReward} points',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _startChallenge(challenge),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: ResponsiveHelper.getAdaptivePadding(context),
                ),
                child: Text(
                  'Start Challenge',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'hard':
        return AppColors.error;
      default:
        return AppColors.mutedText;
    }
  }

  void _startChallenge(Challenge challenge) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be logged in to start a challenge.')),
      );
      return;
    }

    // Prevent starting the same challenge twice
    if (userChallenges.any((uc) => uc.challengeId == challenge.key && !uc.isCompleted)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You have already started this challenge.')),
      );
      return;
    }

    final userChallenge = UserChallenge(
      key: '', // Will be set by Firebase
      userId: userId!,
      challengeId: challenge.key,
      startDate: DateTime.now(),
      completedDate: null,
      isCompleted: false,
      progress: 0,
      taskCompletion: List.filled(challenge.tasks.length, false),
    );

    try {
      await ChallengeDAO.startChallenge(userChallenge);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Challenge started!')),
      );
      await _loadData(); // Refresh challenges and progress
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertError('Failed to start challenge: $e'),
      );
    }
  }

  Widget _buildProgressTab() {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      child: Column(
        children: [
          _buildProgressOverview(),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          _buildActiveChallenges(),
        ],
      ),
    );
  }

  Widget _buildProgressOverview() {
    // Calculate dynamic stats
    final completedCount = userChallenges.where((uc) => uc.isCompleted).length;
    final inProgressCount = userChallenges.where((uc) => !uc.isCompleted).length;
    int totalPoints = 0;
    for (var uc in userChallenges.where((uc) => uc.isCompleted)) {
      final challenge = availableChallenges.firstWhere(
        (c) => c.key == uc.challengeId,
        orElse: () => Challenge(
          key: '',
          title: '',
          description: '',
          category: '',
          durationDays: 0,
          pointsReward: 0,
          difficulty: '',
          tasks: [],
          startDate: DateTime.now(),
          endDate: DateTime.now(),
          isActive: false,
        ),
      );
      if (challenge.key != '') {
        totalPoints += challenge.pointsReward;
      }
    }
    return Card(
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Progress',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            Row(
              children: [
                Expanded(
                  child: _buildProgressStat('Completed', completedCount.toString(), AppColors.success),
                ),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
                Expanded(
                  child: _buildProgressStat('In Progress', inProgressCount.toString(), AppColors.warning),
                ),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
                Expanded(
                  child: _buildProgressStat('Total Points', totalPoints.toString(), AppColors.info),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 24),
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveChallenges() {
    final activeChallenges = userChallenges.where((uc) => !uc.isCompleted).toList();
    if (activeChallenges.isEmpty) {
      return Text('No active challenges.');
    }
    return Column(
      children: activeChallenges.map((uc) {
        final challenge = availableChallenges.firstWhere(
          (c) => c.key == uc.challengeId,
          orElse: () => Challenge(
            key: '',
            title: '',
            description: '',
            category: '',
            durationDays: 0,
            pointsReward: 0,
            difficulty: '',
            tasks: [],
            startDate: DateTime.now(),
            endDate: DateTime.now(),
            isActive: false,
          ),
        );
        if (challenge.key == '') return SizedBox.shrink();
        final daysIn = DateTime.now().difference(uc.startDate).inDays + 1;
        final progress = uc.taskCompletion.isNotEmpty
            ? uc.taskCompletion.where((t) => t).length / uc.taskCompletion.length
            : 0.0;
        return Card(
          margin: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context)),
          child: Padding(
            padding: ResponsiveHelper.getAdaptivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            challenge.title,
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Day $daysIn of ${challenge.durationDays}',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3,
                        vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3,
                        ),
                      ),
                      child: Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.borderLight,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                // List of tasks with checkboxes
                ...List.generate(challenge.tasks.length, (taskIdx) {
                  return CheckboxListTile(
                    title: Text(
                      challenge.tasks[taskIdx],
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        decoration: uc.taskCompletion[taskIdx] ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    value: uc.taskCompletion[taskIdx],
                    onChanged: (checked) async {
                      final updatedTaskCompletion = List<bool>.from(uc.taskCompletion);
                      updatedTaskCompletion[taskIdx] = checked ?? false;
                      final updatedUserChallenge = UserChallenge(
                        key: uc.key,
                        userId: uc.userId,
                        challengeId: uc.challengeId,
                        startDate: uc.startDate,
                        completedDate: (updatedTaskCompletion.every((t) => t)) ? DateTime.now() : uc.completedDate,
                        isCompleted: updatedTaskCompletion.every((t) => t),
                        progress: updatedTaskCompletion.where((t) => t).length,
                        taskCompletion: updatedTaskCompletion,
                      );
                      await ChallengeDAO.updateChallengeProgress(updatedUserChallenge);
                      await _loadData();
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActiveChallengeItem(String title, String subtitle, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3,
                vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.1,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3,
                ),
              ),
              child: Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.borderLight,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _updateProgress(title),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              padding: ResponsiveHelper.getAdaptivePadding(context),
            ),
            child: Text(
              'Update Progress',
              style: TextStyle(
                color: AppColors.white,
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _updateProgress(String challengeTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Update Progress',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'How much progress did you make on "$challengeTitle"?',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Progress updated successfully!',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: Text(
              'Update',
              style: TextStyle(
                color: AppColors.white,
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 