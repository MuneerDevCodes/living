import 'package:flutter/material.dart';
import 'package:living/models/carbon_footprint_model.dart';
import 'package:living/services/carbon_footprint_dao.dart';
import 'package:living/services/auth_helper.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/widgets/alert_error.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';
import 'package:intl/intl.dart';

class CarbonFootprintPage extends StatefulWidget {
  const CarbonFootprintPage({super.key});

  @override
  State<CarbonFootprintPage> createState() => _CarbonFootprintPageState();
}

class _CarbonFootprintPageState extends State<CarbonFootprintPage> with TickerProviderStateMixin {
  List<CarbonFootprintEntry> entries = [];
  List<CarbonGoal> goals = [];
  CarbonAnalytics? analytics;
  bool isLoading = true;
  String? userId;
  late TabController _tabController;
  
  // Carbon footprint variables
  double get currentFootprint => analytics?.weeklyAverage ?? 0.0;
  double get targetFootprint => 5.0; // Target of 5 kg CO2/day

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
        entries = await CarbonFootprintDAO.getUserEntries(userId!);
        goals = await CarbonFootprintDAO.getUserGoals(userId!);
        analytics = await CarbonFootprintDAO.getUserAnalytics(userId!);
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertError('Failed to load data: $e'),
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
                          _buildLogActivityTab(),
                          _buildAnalyticsTab(),
                          _buildGoalsTab(),
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
          Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
          Tab(icon: Icon(Icons.add), text: 'Log Activity'),
          Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          Tab(icon: Icon(Icons.flag), text: 'Goals'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (analytics == null) return _buildEmptyState();
    
    return SingleChildScrollView(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      child: Column(
        children: [
          _buildOverviewCard(),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          _buildRankCard(),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          _buildCategoryBreakdownCard(),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          _buildTipsCard(),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          _buildRecentEntriesCard(),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    final progress = (currentFootprint / targetFootprint).clamp(0.0, 1.0);
    final color = currentFootprint <= targetFootprint ? AppColors.success : AppColors.warning;

    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.eco, color: AppColors.primary, size: 24),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                Text(
                  'Your Carbon Footprint',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 20),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${currentFootprint.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 32),
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        'kg CO2/day',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Target: ${targetFootprint.toStringAsFixed(1)} kg CO2/day',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.borderLight,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankCard() {
    if (analytics == null) return SizedBox.shrink();
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: AppColors.warning, size: 24),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                Text(
                  'Your Rank',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            Text(
              analytics!.rank,
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 24),
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
            Text(
              'Keep up the great work!',
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

  Widget _buildCategoryBreakdownCard() {
    if (analytics?.categoryBreakdown == null) return SizedBox.shrink();
    
    final categories = analytics!.categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: AppColors.primary, size: 24),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                Text(
                  'Breakdown by Category',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            ...categories.take(5).map((category) => Padding(
              padding: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
              child: Row(
                children: [
                  Container(
                    width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8,
                    height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(category.key),
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.4,
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                  Expanded(
                    child: Text(
                      category.key,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '${category.value.toStringAsFixed(1)} kg',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      fontWeight: FontWeight.bold,
                      color: _getCategoryColor(category.key),
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

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Transportation': return AppColors.error;
      case 'Energy': return AppColors.warning;
      case 'Food': return AppColors.success;
      case 'Waste': return AppColors.info;
      case 'Water': return AppColors.secondary;
      case 'Digital': return AppColors.mutedText;
      default: return AppColors.primary;
    }
  }

  Widget _buildTipsCard() {
    final tips = CarbonFootprintDAO.getGeneralTips().take(5).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: AppColors.warning, size: 24),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                Text(
                  'Tips to Reduce Your Footprint',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            ...tips.map((tip) => Padding(
              padding: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        color: AppColors.secondaryText,
                      ),
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

  Widget _buildRecentEntriesCard() {
    final recentEntries = entries.take(5).toList();
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: AppColors.primary, size: 24),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                Text(
                  'Recent Activities',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            if (recentEntries.isEmpty)
              Text(
                'No activities logged yet. Start by logging your first activity!',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  color: AppColors.secondaryText,
                ),
              )
            else
              ...recentEntries.map((entry) => Padding(
                padding: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.activityType,
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${entry.value} ${entry.unit} • ${DateFormat('MMM dd').format(entry.date)}',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '+${entry.carbonImpact.toStringAsFixed(1)} kg',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
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

  Widget _buildLogActivityTab() {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      child: Column(
        children: [
          _buildActivityLogForm(),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          _buildQuickLogButtons(),
        ],
      ),
    );
  }

  Widget _buildActivityLogForm() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add_circle, color: AppColors.success, size: 24),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                Text(
                  'Log New Activity',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            ElevatedButton.icon(
              onPressed: _showActivityLogDialog,
              icon: Icon(Icons.add),
              label: Text('Log Activity'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.white,
                padding: ResponsiveHelper.getAdaptivePadding(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLogButtons() {
    final categories = CarbonFootprintDAO.getAllCategories();
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Log by Category',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            Wrap(
              spacing: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5,
              runSpacing: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5,
              children: categories.map((category) => ElevatedButton(
                onPressed: () => _showCategoryActivityDialog(category),
                child: Text(category),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    if (analytics == null) return _buildEmptyState();
    
    return SingleChildScrollView(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      child: Column(
        children: [
          _buildAnalyticsOverviewCard(),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          _buildTrendsCard(),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          _buildComparisonCard(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsOverviewCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: AppColors.primary, size: 24),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                Text(
                  'Analytics Overview',
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
                  child: _buildAnalyticsItem('Weekly', '${analytics!.weeklyAverage.toStringAsFixed(1)} kg/day'),
                ),
                Expanded(
                  child: _buildAnalyticsItem('Monthly', '${analytics!.monthlyAverage.toStringAsFixed(1)} kg/day'),
                ),
                Expanded(
                  child: _buildAnalyticsItem('Yearly', '${analytics!.yearlyAverage.toStringAsFixed(1)} kg/day'),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsItem('Total Entries', '${analytics!.totalEntries}'),
                ),
                Expanded(
                  child: _buildAnalyticsItem('Reduction', '${analytics!.reductionPercentage.toStringAsFixed(1)}%'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
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

  Widget _buildTrendsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Trends',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            ...analytics!.weeklyTrend.entries.map((entry) => Padding(
              padding: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
              child: Row(
                children: [
                  Expanded(child: Text(entry.key)),
                  Text(
                    '${entry.value.toStringAsFixed(1)} kg',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Global Comparison',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            _buildComparisonItem('Your Average', currentFootprint, AppColors.primary),
            _buildComparisonItem('Global Average', 7.0, AppColors.warning),
            _buildComparisonItem('Target', targetFootprint, AppColors.success),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonItem(String label, double value, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            '${value.toStringAsFixed(1)} kg/day',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsTab() {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      child: Column(
        children: [
          _buildGoalsOverviewCard(),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          _buildGoalsListCard(),
                      SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            _buildAddGoalCard(),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            _buildViewHistoryCard(),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            _buildViewInsightsCard(),
        ],
      ),
    );
  }

  Widget _buildGoalsOverviewCard() {
    final activeGoals = goals.where((goal) => goal.isActive).length;
    final completedGoals = goals.where((goal) => goal.status == 'completed').length;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.flag, color: AppColors.info, size: 24),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                Text(
                  'Carbon Goals',
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
                  child: _buildAnalyticsItem('Active Goals', '$activeGoals'),
                ),
                Expanded(
                  child: _buildAnalyticsItem('Completed', '$completedGoals'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsListCard() {
    final activeGoals = goals.where((goal) => goal.isActive).toList();
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Goals',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            if (activeGoals.isEmpty)
              Text(
                'No active goals. Create your first carbon reduction goal!',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  color: AppColors.secondaryText,
                ),
              )
            else
              ...activeGoals.map((goal) => _buildGoalItem(goal)),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalItem(CarbonGoal goal) {
    final progress = (goal.currentProgress / goal.targetValue).clamp(0.0, 1.0);
    final daysLeft = goal.endDate.difference(DateTime.now()).inDays;
    
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.title,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(goal.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    goal.status.replaceAll('_', ' ').toUpperCase(),
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
              goal.description,
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                color: AppColors.secondaryText,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(goal.status)),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${goal.currentProgress.toStringAsFixed(1)} / ${goal.targetValue.toStringAsFixed(1)} ${goal.unit}',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
                Text(
                  '$daysLeft days left',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'on_track': return AppColors.success;
      case 'ahead': return AppColors.success;
      case 'behind': return AppColors.error;
      case 'completed': return AppColors.info;
      default: return AppColors.warning;
    }
  }

  Widget _buildAddGoalCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _showAddGoalDialog,
              icon: Icon(Icons.add),
              label: Text('Add New Goal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
                foregroundColor: AppColors.white,
                padding: ResponsiveHelper.getAdaptivePadding(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewHistoryCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/carbon-history'),
              icon: Icon(Icons.history),
              label: Text('View History'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.white,
                padding: ResponsiveHelper.getAdaptivePadding(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewInsightsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/carbon-insights'),
              icon: Icon(Icons.insights),
              label: Text('View Insights'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: AppColors.white,
                padding: ResponsiveHelper.getAdaptivePadding(context),
              ),
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
            Icons.eco,
            size: 64,
            color: AppColors.secondaryText,
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          Text(
            'No data available',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
              fontWeight: FontWeight.bold,
              color: AppColors.secondaryText,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
          Text(
            'Start by logging your first activity!',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  void _showActivityLogDialog() {
    showDialog(
      context: context,
      builder: (context) => ActivityLogDialog(
        onActivityLogged: () {
          Navigator.pop(context);
          _loadData();
        },
      ),
    );
  }

  void _showCategoryActivityDialog(String category) {
    showDialog(
      context: context,
      builder: (context) => CategoryActivityDialog(
        category: category,
        onActivityLogged: () {
          Navigator.pop(context);
          _loadData();
        },
      ),
    );
  }

  void _showAddGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => AddGoalDialog(
        onGoalAdded: () {
          Navigator.pop(context);
          _loadData();
        },
      ),
    );
  }
}

// Activity Log Dialog
class ActivityLogDialog extends StatefulWidget {
  final VoidCallback onActivityLogged;

  const ActivityLogDialog({super.key, required this.onActivityLogged});

  @override
  State<ActivityLogDialog> createState() => _ActivityLogDialogState();
}

class _ActivityLogDialogState extends State<ActivityLogDialog> {
  String? selectedCategory;
  String? selectedActivity;
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final categories = CarbonFootprintDAO.getAllCategories();
    final activities = selectedCategory != null 
        ? CarbonFootprintDAO.getActivityTypesByCategory(selectedCategory!)
        : [];

    return AlertDialog(
      title: Text('Log Carbon Activity'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(labelText: 'Category'),
              items: categories.map((category) => 
                DropdownMenuItem(value: category, child: Text(category))
              ).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                  selectedActivity = null;
                });
              },
            ),
            SizedBox(height: 16),
            if (selectedCategory != null)
              DropdownButtonFormField<String>(
                value: selectedActivity,
                decoration: InputDecoration(labelText: 'Activity'),
                items: activities.map((activity) => 
                  DropdownMenuItem<String>(value: activity.name, child: Text(activity.name))
                ).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedActivity = value;
                  });
                },
              ),
            SizedBox(height: 16),
            TextField(
              controller: _valueController,
              decoration: InputDecoration(
                labelText: 'Value',
                suffixText: selectedActivity != null 
                    ? CarbonFootprintDAO.getActivityByName(selectedActivity!)?.unit ?? ''
                    : '',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(labelText: 'Location (optional)'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _logActivity,
          child: Text('Log Activity'),
        ),
      ],
    );
  }

  void _logActivity() async {
    if (selectedActivity == null || _valueController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    try {
      final value = double.parse(_valueController.text);
      final activity = CarbonFootprintDAO.getActivityByName(selectedActivity!);
      if (activity == null) return;

      final carbonImpact = CarbonFootprintDAO.calculateCarbonImpact(selectedActivity!, value);
      final userId = AuthService.getCurrentUserId();
      
      if (userId == null) return;

      final entry = CarbonFootprintEntry(
        key: '',
        userId: userId,
        activityType: selectedActivity!,
        value: value,
        unit: activity.unit,
        carbonImpact: carbonImpact,
        date: DateTime.now(),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        category: activity.category,
        subcategory: activity.subcategory,
        emissionFactor: activity.carbonFactor,
        location: _locationController.text.isNotEmpty ? _locationController.text : '',
      );

      await CarbonFootprintDAO.addEntry(entry);
      widget.onActivityLogged();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Activity logged successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging activity: $e')),
      );
    }
  }
}

// Category Activity Dialog
class CategoryActivityDialog extends StatefulWidget {
  final String category;
  final VoidCallback onActivityLogged;

  const CategoryActivityDialog({
    super.key, 
    required this.category, 
    required this.onActivityLogged
  });

  @override
  State<CategoryActivityDialog> createState() => _CategoryActivityDialogState();
}

class _CategoryActivityDialogState extends State<CategoryActivityDialog> {
  String? selectedActivity;
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final activities = CarbonFootprintDAO.getActivityTypesByCategory(widget.category);

    return AlertDialog(
      title: Text('Log ${widget.category} Activity'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedActivity,
              decoration: InputDecoration(labelText: 'Activity'),
              items: activities.map((activity) => 
                DropdownMenuItem(value: activity.name, child: Text(activity.name))
              ).toList(),
              onChanged: (value) {
                setState(() {
                  selectedActivity = value;
                });
              },
            ),
            SizedBox(height: 16),
            TextField(
              controller: _valueController,
              decoration: InputDecoration(
                labelText: 'Value',
                suffixText: selectedActivity != null 
                    ? CarbonFootprintDAO.getActivityByName(selectedActivity!)?.unit ?? ''
                    : '',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _logActivity,
          child: Text('Log Activity'),
        ),
      ],
    );
  }

  void _logActivity() async {
    if (selectedActivity == null || _valueController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    try {
      final value = double.parse(_valueController.text);
      final activity = CarbonFootprintDAO.getActivityByName(selectedActivity!);
      if (activity == null) return;

      final carbonImpact = CarbonFootprintDAO.calculateCarbonImpact(selectedActivity!, value);
      final userId = AuthService.getCurrentUserId();
      
      if (userId == null) return;

      final entry = CarbonFootprintEntry(
        key: '',
        userId: userId,
        activityType: selectedActivity!,
        value: value,
        unit: activity.unit,
        carbonImpact: carbonImpact,
        date: DateTime.now(),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        category: activity.category,
        subcategory: activity.subcategory,
        emissionFactor: activity.carbonFactor,
      );

      await CarbonFootprintDAO.addEntry(entry);
      widget.onActivityLogged();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Activity logged successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging activity: $e')),
      );
    }
  }
}

// Add Goal Dialog
class AddGoalDialog extends StatefulWidget {
  final VoidCallback onGoalAdded;

  const AddGoalDialog({super.key, required this.onGoalAdded});

  @override
  State<AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<AddGoalDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  String? selectedCategory;
  DateTime? startDate;
  DateTime? endDate;

  @override
  Widget build(BuildContext context) {
    final categories = CarbonFootprintDAO.getAllCategories();

    return AlertDialog(
      title: Text('Add Carbon Goal'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Goal Title'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(labelText: 'Category'),
              items: categories.map((category) => 
                DropdownMenuItem(value: category, child: Text(category))
              ).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
            ),
            SizedBox(height: 16),
            TextField(
              controller: _targetController,
              decoration: InputDecoration(labelText: 'Target Value'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          startDate = date;
                        });
                      }
                    },
                    child: Text('Start Date'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          endDate = date;
                        });
                      }
                    },
                    child: Text('End Date'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addGoal,
          child: Text('Add Goal'),
        ),
      ],
    );
  }

  void _addGoal() async {
    if (_titleController.text.isEmpty || 
        _descriptionController.text.isEmpty || 
        _targetController.text.isEmpty ||
        selectedCategory == null ||
        startDate == null ||
        endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      final targetValue = double.parse(_targetController.text);
      final userId = AuthService.getCurrentUserId();
      
      if (userId == null) return;

      final goal = CarbonGoal(
        key: '',
        userId: userId,
        title: _titleController.text,
        description: _descriptionController.text,
        targetValue: targetValue,
        unit: 'kg CO2',
        startDate: startDate!,
        endDate: endDate!,
        category: selectedCategory!,
        isActive: true,
        currentProgress: 0.0,
        status: 'on_track',
      );

      await CarbonFootprintDAO.addGoal(goal);
      widget.onGoalAdded();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Goal added successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding goal: $e')),
      );
    }
  }
} 