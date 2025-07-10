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

  void _startChallenge(Challenge challenge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Start Challenge',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you ready to start "${challenge.title}"?',
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
                    'Challenge started successfully!',
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
              'Start',
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
                  child: _buildProgressStat('Completed', '12', AppColors.success),
                ),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
                Expanded(
                  child: _buildProgressStat('In Progress', '3', AppColors.warning),
                ),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
                Expanded(
                  child: _buildProgressStat('Total Points', '450', AppColors.info),
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
    return Card(
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Challenges',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            // Sample active challenge
            _buildActiveChallengeItem(
              'Reduce Plastic Usage',
              'Day 5 of 30',
              0.6,
              AppColors.success,
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
            _buildActiveChallengeItem(
              'Walk to Work',
              'Day 12 of 21',
              0.8,
              AppColors.warning,
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
            _buildActiveChallengeItem(
              'Energy Conservation',
              'Day 3 of 14',
              0.3,
              AppColors.info,
            ),
          ],
        ),
      ),
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