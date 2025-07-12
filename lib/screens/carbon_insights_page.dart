import 'package:flutter/material.dart';
import 'package:living/services/carbon_insights_service.dart';
import 'package:living/services/auth_helper.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/widgets/alert_error.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';

class CarbonInsightsPage extends StatefulWidget {
  const CarbonInsightsPage({super.key});

  @override
  State<CarbonInsightsPage> createState() => _CarbonInsightsPageState();
}

class _CarbonInsightsPageState extends State<CarbonInsightsPage> with TickerProviderStateMixin {
  CarbonInsights? insights;
  List<CarbonLeaderboardEntry> leaderboard = [];
  List<CarbonChallenge> challenges = [];
  bool isLoading = true;
  String? userId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);
      userId = AuthService.getCurrentUserId();
      if (userId != null) {
        insights = await CarbonInsightsService.getUserInsights(userId!);
        leaderboard = CarbonInsightsService.getLeaderboard();
        challenges = CarbonInsightsService.getChallenges();
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertError('Failed to load insights: $e'),
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
    return Scaffold(
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
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(),
                          _buildAchievementsTab(),
                          _buildRecommendationsTab(),
                          _buildSocialTab(),
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
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.primary,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.white,
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.white.withOpacity(0.7),
        tabs: [
          Tab(icon: Icon(Icons.insights), text: 'Overview'),
          Tab(icon: Icon(Icons.emoji_events), text: 'Achievements'),
          Tab(icon: Icon(Icons.lightbulb), text: 'Recommendations'),
          Tab(icon: Icon(Icons.people), text: 'Social'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (insights == null) return _buildEmptyState();

    return SingleChildScrollView(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      child: Column(
        children: [
          _buildUserStatsCard(),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          _buildLevelProgressCard(),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          _buildInsightsCard(),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          _buildChallengesCard(),
        ],
      ),
    );
  }

  Widget _buildUserStatsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    'L${insights!.level}',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level ${insights!.level}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 20),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${insights!.totalPoints} points earned',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Entries', '${insights!.socialStats.totalEntries}', Icons.list),
                ),
                Expanded(
                  child: _buildStatItem('Streak', '${insights!.socialStats.streakDays} days', Icons.local_fire_department),
                ),
                Expanded(
                  child: _buildStatItem('Achievements', '${insights!.achievements.length}', Icons.emoji_events),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
            fontWeight: FontWeight.bold,
          ),
        ),
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

  Widget _buildLevelProgressCard() {
    final nextLevelPoints = _getNextLevelPoints(insights!.level);
    final progress = insights!.totalPoints / nextLevelPoints;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress to Level ${insights!.level + 1}',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            Text(
              '${insights!.totalPoints} / $nextLevelPoints points',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getNextLevelPoints(int currentLevel) {
    switch (currentLevel) {
      case 1: return 25;
      case 2: return 50;
      case 3: return 100;
      case 4: return 200;
      case 5: return 300;
      case 6: return 400;
      case 7: return 600;
      case 8: return 800;
      case 9: return 1000;
      default: return 1000;
    }
  }

  Widget _buildInsightsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: AppColors.primary, size: 24),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                Text(
                  'Recent Insights',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            ...insights!.insights.take(3).map((insight) => Padding(
              padding: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.icon,
                    style: TextStyle(fontSize: 20),
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insight.title,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          insight.message,
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
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengesCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag, color: AppColors.warning, size: 24),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                Text(
                  'Available Challenges',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            ...challenges.take(2).map((challenge) => Padding(
              padding: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
              child: Card(
                child: Padding(
                  padding: ResponsiveHelper.getAdaptivePadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              challenge.title,
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getDifficultyColor(challenge.difficulty),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              challenge.difficulty,
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                      Text(
                        challenge.description,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                          color: AppColors.secondaryText,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 12, color: AppColors.secondaryText),
                          SizedBox(width: 4),
                          Text(
                            '${challenge.duration} days',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.secondaryText,
                            ),
                          ),
                          Spacer(),
                          Icon(Icons.star, size: 12, color: AppColors.warning),
                          SizedBox(width: 4),
                          Text(
                            '${challenge.reward} points',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsTab() {
    if (insights == null) return _buildEmptyState();

    return SingleChildScrollView(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      child: Column(
        children: [
          _buildAchievementsOverview(),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          _buildAchievementsList(),
        ],
      ),
    );
  }

  Widget _buildAchievementsOverview() {
    final totalAchievements = CarbonInsightsService.achievements.length;
    final unlockedAchievements = insights!.achievements.length;
    final progress = unlockedAchievements / totalAchievements;

    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          children: [
            Text(
              'Achievements Progress',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            Text(
              '$unlockedAchievements / $totalAchievements unlocked',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsList() {
    return Column(
      children: CarbonInsightsService.achievements.map((achievement) {
        final isUnlocked = insights!.achievements.any((a) => a.id == achievement.id);
        
        return Card(
          margin: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
          child: Padding(
            padding: ResponsiveHelper.getAdaptivePadding(context),
            child: Row(
              children: [
                Container(
                  width: ResponsiveHelper.getAdaptiveSpacing(context) * 1.5,
                  height: ResponsiveHelper.getAdaptiveSpacing(context) * 1.5,
                  decoration: BoxDecoration(
                    color: isUnlocked ? AppColors.success : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.75,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      achievement.icon,
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement.title,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                          fontWeight: FontWeight.bold,
                          color: isUnlocked ? AppColors.primary : AppColors.secondaryText,
                        ),
                      ),
                      Text(
                        achievement.description,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${achievement.points} pts',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? AppColors.success : AppColors.secondaryText,
                      ),
                    ),
                    if (isUnlocked)
                      Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 16,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecommendationsTab() {
    if (insights == null) return _buildEmptyState();

    return SingleChildScrollView(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      child: Column(
        children: [
          _buildRecommendationsList(),
        ],
      ),
    );
  }

  Widget _buildRecommendationsList() {
    return Column(
      children: insights!.recommendations.map((recommendation) => Card(
        margin: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
        child: Padding(
          padding: ResponsiveHelper.getAdaptivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getImpactColor(recommendation.impact),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      recommendation.impact,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(recommendation.difficulty),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      recommendation.difficulty,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
              Text(
                recommendation.title,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
              Text(
                recommendation.description,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  color: AppColors.secondaryText,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
              Row(
                children: [
                  Icon(Icons.trending_down, size: 16, color: AppColors.success),
                  SizedBox(width: 4),
                  Text(
                    'Estimated reduction: ${recommendation.estimatedReduction.toStringAsFixed(1)} kg CO2/day',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildSocialTab() {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      child: Column(
        children: [
          _buildLeaderboardCard(),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          _buildSocialStatsCard(),
        ],
      ),
    );
  }

  Widget _buildLeaderboardCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.leaderboard, color: AppColors.warning, size: 24),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                Text(
                  'Leaderboard',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            ...leaderboard.map((entry) => Padding(
              padding: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
              child: Row(
                children: [
                  Container(
                    width: ResponsiveHelper.getAdaptiveSpacing(context) * 1.2,
                    height: ResponsiveHelper.getAdaptiveSpacing(context) * 1.2,
                    decoration: BoxDecoration(
                      color: _getRankColor(entry.rank),
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.6,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${entry.rank}',
                        style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
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
                          entry.username,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Level ${entry.level} • ${entry.weeklyAverage.toStringAsFixed(1)} kg/day',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${entry.totalPoints} pts',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialStatsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Social Stats',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Best Category', insights!.socialStats.bestCategory, Icons.star),
                ),
                Expanded(
                  child: _buildStatItem('Improvement', '${insights!.socialStats.improvementPercentage.toStringAsFixed(1)}%', Icons.trending_up),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insights,
            size: 64,
            color: AppColors.secondaryText,
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          Text(
            'No insights available',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
              fontWeight: FontWeight.bold,
              color: AppColors.secondaryText,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
          Text(
            'Start logging activities to see your insights!',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy': return AppColors.success;
      case 'medium': return AppColors.warning;
      case 'hard': return AppColors.error;
      default: return AppColors.primary;
    }
  }

  Color _getImpactColor(String impact) {
    switch (impact.toLowerCase()) {
      case 'high': return AppColors.error;
      case 'medium': return AppColors.warning;
      case 'low': return AppColors.success;
      default: return AppColors.primary;
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1: return Colors.amber;
      case 2: return Colors.grey;
      case 3: return Colors.brown;
      default: return AppColors.primary;
    }
  }
} 