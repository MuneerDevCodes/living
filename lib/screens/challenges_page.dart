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

/// ChallengesPage displays sustainability challenges and user progress, using responsive and theme-driven design.
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

  /// Build method for the challenges page, using only ResponsiveHelper and AppTheme/AppColors.
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
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
                Container(
                  width: ResponsiveHelper.getAdaptiveSpacing(context) * 2,
                  height: ResponsiveHelper.getAdaptiveSpacing(context) * 2,
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(challenge.difficulty),
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
                  ),
                  child: Center(
                    child: Text(
                      challenge.icon,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 20),
                      ),
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
            
            // Environmental Impact
            if (challenge.environmentalImpact.isNotEmpty)
              Container(
                padding: EdgeInsets.all(ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.eco,
                      size: ResponsiveHelper.getAdaptiveIconSize(context),
                      color: AppColors.success,
                    ),
                    SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                    Expanded(
                      child: Text(
                        challenge.environmentalImpact,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            
            // Benefits
            if (challenge.benefits.isNotEmpty)
              Container(
                padding: EdgeInsets.all(ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      size: ResponsiveHelper.getAdaptiveIconSize(context),
                      color: AppColors.info,
                    ),
                    SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                    Expanded(
                      child: Text(
                        challenge.benefits,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                          color: AppColors.info,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            
            // Carbon Reduction
            if (challenge.carbonReduction > 0)
              Container(
                padding: EdgeInsets.all(ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud,
                      size: ResponsiveHelper.getAdaptiveIconSize(context),
                      color: AppColors.warning,
                    ),
                    SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                    Text(
                      'Saves ${challenge.carbonReduction.toStringAsFixed(1)} kg CO₂ per day',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
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
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3,
                    vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.1,
                  ),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(challenge.difficulty).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3),
                  ),
                  child: Text(
                    challenge.difficulty,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 10),
                      color: _getDifficultyColor(challenge.difficulty),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
            
            // Tips Section
            if (challenge.tips.isNotEmpty) ...[
              ExpansionTile(
                title: Text(
                  '💡 Tips for Success',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
                children: challenge.tips.map((tip) => Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4,
                    vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.1,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                          color: AppColors.primary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          tip,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
            ],
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showChallengeDetails(challenge),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: ResponsiveHelper.getAdaptivePadding(context),
                ),
                child: Text(
                  'Learn More',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
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
                    fontWeight: FontWeight.bold,
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
        SnackBar(
          content: Text('🎉 Challenge started! Good luck on your sustainability journey!'),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadData(); // Refresh challenges and progress
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertError('Failed to start challenge: $e'),
      );
    }
  }

  void _showCompletionCelebration(Challenge challenge, double carbonSaved) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
        ),
        title: Row(
          children: [
            Text(
              '🎉 Congratulations!',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 20),
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You\'ve completed "${challenge.title}"!',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            Container(
              padding: EdgeInsets.all(ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCelebrationStat('Points Earned', '${challenge.pointsReward}', Icons.star),
                      _buildCelebrationStat('CO₂ Saved', '${carbonSaved.toStringAsFixed(1)} kg', Icons.eco),
                    ],
                  ),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                  Text(
                    'Your impact: ${challenge.environmentalImpact}',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                      color: AppColors.secondaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: ResponsiveHelper.getAdaptivePadding(context),
            ),
            child: Text(
              'Continue Journey',
              style: TextStyle(
                color: AppColors.white,
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrationStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.success,
          size: ResponsiveHelper.getAdaptiveIconSize(context),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.1),
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
            fontWeight: FontWeight.bold,
            color: AppColors.success,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 10),
            color: AppColors.secondaryText,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
    // Calculate dynamic stats
    final completedCount = userChallenges.where((uc) => uc.isCompleted).length;
    final inProgressCount = userChallenges.where((uc) => !uc.isCompleted).length;
    int totalPoints = 0;
    double totalCarbonSaved = 0.0;
    
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
        totalCarbonSaved += challenge.carbonReduction * challenge.durationDays;
      }
    }
    
    return Card(
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: AppColors.primary,
                  size: ResponsiveHelper.getAdaptiveIconSize(context),
                ),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                Text(
                  'Your Sustainability Journey',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            Row(
              children: [
                Expanded(
                  child: _buildProgressStat('Completed', completedCount.toString(), AppColors.success, Icons.check_circle),
                ),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
                Expanded(
                  child: _buildProgressStat('In Progress', inProgressCount.toString(), AppColors.warning, Icons.pending),
                ),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
                Expanded(
                  child: _buildProgressStat('Total Points', totalPoints.toString(), AppColors.info, Icons.star),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            
            // Environmental Impact Summary
            Container(
              padding: EdgeInsets.all(ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.eco,
                    color: AppColors.success,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Environmental Impact',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.1),
                        Text(
                          'You\'ve saved ${totalCarbonSaved.toStringAsFixed(1)} kg of CO₂ through completed challenges!',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStat(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3),
          ),
          child: Icon(
            icon,
            color: color,
            size: ResponsiveHelper.getAdaptiveIconSize(context),
          ),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 24),
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.1),
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
            color: AppColors.secondaryText,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActiveChallenges() {
    final activeChallenges = userChallenges.where((uc) => !uc.isCompleted).toList();
    if (activeChallenges.isEmpty) {
      return Container(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          children: [
            Icon(
              Icons.celebration,
              size: ResponsiveHelper.getAdaptiveIconSize(context) * 2,
              color: AppColors.success,
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            Text(
              'No Active Challenges',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            Text(
              'Start a new challenge to continue your sustainability journey!',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
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
        final completedTasks = uc.taskCompletion.where((t) => t).length;
        final totalTasks = uc.taskCompletion.length;
        final carbonSaved = challenge.carbonReduction * daysIn * progress;
        
        return Card(
          margin: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context)),
          child: Padding(
            padding: ResponsiveHelper.getAdaptivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: ResponsiveHelper.getAdaptiveSpacing(context) * 1.5,
                      height: ResponsiveHelper.getAdaptiveSpacing(context) * 1.5,
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(challenge.difficulty),
                        borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
                      ),
                      child: Center(
                        child: Text(
                          challenge.icon,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
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
                        borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3),
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
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                
                // Progress Bar
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.borderLight,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                
                // Progress Details
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$completedTasks/$totalTasks tasks completed',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                    if (carbonSaved > 0)
                      Text(
                        '${carbonSaved.toStringAsFixed(1)} kg CO₂ saved',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                
                // Tasks List
                Text(
                  'Daily Tasks:',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                
                ...List.generate(challenge.tasks.length, (taskIdx) {
                  return CheckboxListTile(
                    title: Text(
                      challenge.tasks[taskIdx],
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        decoration: uc.taskCompletion[taskIdx] ? TextDecoration.lineThrough : null,
                        color: uc.taskCompletion[taskIdx] ? AppColors.success : AppColors.primaryText,
                      ),
                    ),
                    value: uc.taskCompletion[taskIdx],
                    onChanged: (checked) async {
                      final updatedTaskCompletion = List<bool>.from(uc.taskCompletion);
                      updatedTaskCompletion[taskIdx] = checked ?? false;
                      final isCompleted = updatedTaskCompletion.every((t) => t);
                      final updatedUserChallenge = UserChallenge(
                        key: uc.key,
                        userId: uc.userId,
                        challengeId: uc.challengeId,
                        startDate: uc.startDate,
                        completedDate: isCompleted ? DateTime.now() : uc.completedDate,
                        isCompleted: isCompleted,
                        progress: updatedTaskCompletion.where((t) => t).length,
                        taskCompletion: updatedTaskCompletion,
                      );
                      await ChallengeDAO.updateChallengeProgress(updatedUserChallenge);
                      
                      // Show celebration if challenge is completed
                      if (isCompleted) {
                        final carbonSaved = challenge.carbonReduction * challenge.durationDays;
                        _showCompletionCelebration(challenge, carbonSaved);
                      }
                      
                      await _loadData();
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.success,
                    checkColor: AppColors.white,
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
                color: color.withOpacity(0.1),
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

  void _showChallengeDetails(Challenge challenge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
        ),
        title: Text(
          challenge.title,
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 20),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                challenge.description,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  color: AppColors.secondaryText,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Text(
                'Category: ${challenge.category}',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Text(
                'Duration: ${challenge.durationDays} days',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Text(
                'Points Reward: ${challenge.pointsReward}',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Text(
                'Difficulty: ${challenge.difficulty}',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Text(
                'Environmental Impact: ${challenge.environmentalImpact}',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Text(
                'Benefits: ${challenge.benefits}',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Text(
                'Carbon Reduction: ${challenge.carbonReduction.toStringAsFixed(1)} kg CO₂ per day',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Text(
                'Tips:',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  fontWeight: FontWeight.w500,
                ),
              ),
              ...challenge.tips.map((tip) => Padding(
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.1,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                        color: AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 