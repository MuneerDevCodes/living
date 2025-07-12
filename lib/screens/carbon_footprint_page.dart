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

  // Helper method for category icons
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Transportation': return Icons.directions_car;
      case 'Energy': return Icons.electric_bolt;
      case 'Food': return Icons.restaurant;
      case 'Waste': return Icons.delete;
      case 'Water': return Icons.water_drop;
      case 'Digital': return Icons.computer;
      default: return Icons.category;
    }
  }

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
    final highestCategory = analytics!.categoryBreakdown.entries.isNotEmpty
        ? analytics!.categoryBreakdown.entries.reduce((a, b) => a.value > b.value ? a : b)
        : null;
    final lowestCategory = analytics!.categoryBreakdown.entries.isNotEmpty
        ? analytics!.categoryBreakdown.entries.reduce((a, b) => a.value < b.value ? a : b)
        : null;
    final highestDay = analytics!.weeklyTrend.entries.isNotEmpty
        ? analytics!.weeklyTrend.entries.reduce((a, b) => a.value > b.value ? a : b)
        : null;

    return SingleChildScrollView(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Carbon Footprint
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This Week',
                    style: TextStyle(fontSize: 16, color: AppColors.secondaryText),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${analytics!.weeklyAverage.toStringAsFixed(1)} kg CO₂',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Total this month: ${analytics!.monthlyAverage.toStringAsFixed(1)} kg CO₂',
                    style: TextStyle(fontSize: 14, color: AppColors.secondaryText),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),

          // Category Breakdown
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.pie_chart, color: AppColors.primary, size: 24),
                      SizedBox(width: 8),
                      Text('Category Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 16),
                  ...analytics!.categoryBreakdown.entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(_getCategoryIcon(entry.key), color: AppColors.primary, size: 18),
                        SizedBox(width: 8),
                        Expanded(child: Text(entry.key)),
                        Container(
                          width: 80,
                          height: 8,
                          margin: EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (analytics!.categoryBreakdown.values.isNotEmpty && (analytics!.categoryBreakdown.values.reduce((a, b) => a > b ? a : b)) > 0)
                                ? (entry.value / (analytics!.categoryBreakdown.values.reduce((a, b) => a > b ? a : b))).clamp(0.0, 1.0)
                                : 0.0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _getCategoryColor(entry.key),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        Text('${entry.value.toStringAsFixed(1)} kg CO₂', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),

          // Weekly Trends
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.show_chart, color: AppColors.info, size: 24),
                      SizedBox(width: 8),
                      Text('Weekly Trends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 16),
                  ...analytics!.weeklyTrend.entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(child: Text(entry.key)),
                        Text('${entry.value.toStringAsFixed(1)} kg CO₂', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )),
                  if (highestDay != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Your highest footprint was on ${highestDay.key}: ${highestDay.value.toStringAsFixed(1)} kg CO₂',
                        style: TextStyle(fontSize: 14, color: AppColors.error, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),

          // Quick Insights
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  if (highestCategory != null)
                    Text('🚗 Highest: ${highestCategory.key}: ${highestCategory.value.toStringAsFixed(1)} kg CO₂'),
                  if (lowestCategory != null)
                    Text('🥗 Lowest: ${lowestCategory.key}: ${lowestCategory.value.toStringAsFixed(1)} kg CO₂'),
                  Text('⚡ Energy usage steady this week'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsTab() {
    if (goals.isEmpty) return _buildEmptyState();
    final activeGoal = goals.firstWhere((g) => g.isActive, orElse: () => goals.first);
    final progress = (activeGoal.currentProgress / activeGoal.targetValue).clamp(0.0, 1.0);
    final completedCount = goals.where((g) => g.status == 'completed').length;
    final bestWeek = analytics?.weeklyTrend.values.isNotEmpty == true
        ? analytics!.weeklyTrend.values.reduce((a, b) => a < b ? a : b)
        : null;
    final highestCategory = analytics?.categoryBreakdown.entries.isNotEmpty == true
        ? analytics!.categoryBreakdown.entries.reduce((a, b) => a.value > b.value ? a : b)
        : null;
    String tip = '';
    if (highestCategory != null) {
      switch (highestCategory.key) {
        case 'Transportation':
          tip = 'Try taking public transport tomorrow to reduce by 3 kg CO₂';
          break;
        case 'Energy':
          tip = 'Switch off appliances when not in use to save energy';
          break;
        case 'Food':
          tip = 'Choose more plant-based meals this week';
          break;
        default:
          tip = 'Keep up the good work!';
      }
    }
    return SingleChildScrollView(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Goal Display
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Weekly Goal', style: TextStyle(fontSize: 16, color: AppColors.secondaryText)),
                  SizedBox(height: 8),
                  Text(
                    'Under ${activeGoal.targetValue.toStringAsFixed(1)} kg CO₂',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),

          // Progress Bar
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.borderLight,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        '${activeGoal.currentProgress.toStringAsFixed(1)} / ${activeGoal.targetValue.toStringAsFixed(1)} kg CO₂',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('${(progress * 100).toStringAsFixed(0)}% completed', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),

          // Motivational Tip
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: AppColors.warning, size: 20),
                  SizedBox(width: 8),
                  Expanded(child: Text(tip, style: TextStyle(fontSize: 14))),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),

          // Past Achievements
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  if (completedCount > 0)
                    Row(children: [
                      Icon(Icons.emoji_events, color: AppColors.success, size: 20),
                      SizedBox(width: 4),
                      Text('Goal Achieved $completedCount times this month!', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 16),
                    ]),
                  if (bestWeek != null)
                    Row(children: [
                      Icon(Icons.star, color: AppColors.info, size: 20),
                      SizedBox(width: 4),
                      Text('Best week: ${bestWeek.toStringAsFixed(1)} kg CO₂', style: TextStyle(fontSize: 14)),
                    ]),
                ],
              ),
            ),
          ),
        ],
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
  bool isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final categories = CarbonFootprintDAO.getAllCategories();
    final List<ActivityType> activities = selectedCategory != null 
        ? CarbonFootprintDAO.getActivityTypesByCategory(selectedCategory!)
        : <ActivityType>[];

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ResponsiveHelper.isMobile(context) ? double.infinity : 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: ResponsiveHelper.getAdaptivePadding(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with guidance
                _buildHeader(),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                
                // Category Selection with guidance
                _buildCategorySection(categories),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                
                // Activity Selection with guidance
                if (selectedCategory != null) ...[
                  _buildActivitySection(activities),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                ],
                
                // Value Input with guidance
                if (selectedActivity != null) ...[
                  _buildValueSection(),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                ],
                
                // Optional fields
                if (selectedActivity != null) ...[
                  _buildOptionalFields(),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                ],
                
                // Action buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.eco, color: AppColors.primary, size: 24),
            SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
            Text(
              'Log Your Carbon Activity',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 20),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
        Text(
          'Track your daily activities and see their environmental impact. This helps you understand your carbon footprint and find ways to reduce it.',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(List<String> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category, color: AppColors.info, size: 20),
            SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            Text(
              'Step 1: Choose Activity Category',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
        Text(
          'Select the category that best describes your activity. This helps us calculate the most accurate carbon impact.',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
            color: AppColors.secondaryText,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
        DropdownButtonFormField<String>(
          value: selectedCategory,
          decoration: InputDecoration(
            labelText: 'Activity Category',
            border: OutlineInputBorder(),
            helperText: 'What type of activity are you logging?',
          ),
          items: categories.map((category) => 
            DropdownMenuItem(
              value: category, 
              child: Row(
                children: [
                  Icon(_getCategoryIcon(category), size: 16),
                  SizedBox(width: 8),
                  Text(category),
                ],
              ),
            )
          ).toList(),
          onChanged: (value) {
            setState(() {
              selectedCategory = value;
              selectedActivity = null;
              _valueController.clear();
            });
          },
        ),
      ],
    );
  }

  Widget _buildActivitySection(List<ActivityType> activities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.list, color: AppColors.info, size: 20),
            SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            Text(
              'Step 2: Select Specific Activity',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
        Text(
          'Choose the specific activity you performed. Each has different environmental impacts.',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
            color: AppColors.secondaryText,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
        DropdownButtonFormField<String>(
          value: selectedActivity,
          decoration: InputDecoration(
            labelText: 'Specific Activity',
            border: OutlineInputBorder(),
            helperText: 'What exactly did you do?',
          ),
          items: activities.map((activity) =>
            DropdownMenuItem<String>(
              value: activity.name,
              child: Row(
                children: [
                  Text(
                    activity.icon,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(width: 4),
                  Text(
                    activity.name,
                    style: TextStyle(fontSize: 14, height: 1),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            )
          ).toList(),
          onChanged: (value) {
            setState(() {
              selectedActivity = value;
              _valueController.clear();
            });
          },
        ),
        if (selectedActivity != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 4.0),
            child: Text(
              CarbonFootprintDAO.getActivityByName(selectedActivity!)?.description ?? '',
              style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
            ),
          ),
      ],
    );
  }

  Widget _buildValueSection() {
    final activity = CarbonFootprintDAO.getActivityByName(selectedActivity!);
    if (activity == null) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.input, color: AppColors.info, size: 20),
            SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            Text(
              'Step 3: Enter Activity Details',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
        Text(
          'Enter the amount of your activity. This helps calculate your carbon footprint accurately.',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
            color: AppColors.secondaryText,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
        TextField(
          controller: _valueController,
          decoration: InputDecoration(
            labelText: 'Amount',
            suffixText: activity.unit,
            border: OutlineInputBorder(),
            helperText: _getValueHelperText(activity),
            prefixIcon: Icon(Icons.calculate),
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            setState(() {});
          },
        ),
        if (_valueController.text.isNotEmpty) ...[
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
          _buildCarbonPreview(),
        ],
      ],
    );
  }

  Widget _buildCarbonPreview() {
    try {
      final value = double.parse(_valueController.text);
      final carbonImpact = CarbonFootprintDAO.calculateCarbonImpact(selectedActivity!, value);
      final activity = CarbonFootprintDAO.getActivityByName(selectedActivity!);
      
      return Container(
        padding: ResponsiveHelper.getAdaptivePadding(context) * 0.5,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primary, size: 16),
            SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            Expanded(
              child: Text(
                'This activity will generate ${carbonImpact.toStringAsFixed(2)} kg CO₂',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return SizedBox.shrink();
    }
  }

  Widget _buildOptionalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.notes, color: AppColors.info, size: 20),
            SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            Text(
              'Step 4: Additional Details (Optional)',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
        Text(
          'Add location and notes to help you remember and track your activities better.',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
            color: AppColors.secondaryText,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
        TextField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: 'Location',
            border: OutlineInputBorder(),
            helperText: 'e.g., Home to Work, Grocery Store, etc.',
            prefixIcon: Icon(Icons.location_on),
          ),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
        TextField(
          controller: _notesController,
          decoration: InputDecoration(
            labelText: 'Notes',
            border: OutlineInputBorder(),
            helperText: 'Any additional details about this activity',
            prefixIcon: Icon(Icons.note),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ),
        SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
        Expanded(
          child: ElevatedButton(
            onPressed: isSubmitting ? null : _logActivity,
            child: isSubmitting 
                ? SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Log Activity'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
            ),
          ),
        ),
      ],
    );
  }

  String _getValueHelperText(ActivityType activity) {
    switch (activity.category) {
      case 'Transportation':
        return 'e.g., 12 km from home to work';
      case 'Energy':
        return 'e.g., 15 kWh of electricity used';
      case 'Food':
        return 'e.g., 0.5 kg of beef consumed';
      case 'Waste':
        return 'e.g., 2 kg of waste disposed';
      case 'Water':
        return 'e.g., 50 L of hot water used';
      case 'Digital':
        return 'e.g., 2 hours of video streaming';
      default:
        return 'Enter the amount of your activity';
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Transportation': return Icons.directions_car;
      case 'Energy': return Icons.electric_bolt;
      case 'Food': return Icons.restaurant;
      case 'Waste': return Icons.delete;
      case 'Water': return Icons.water_drop;
      case 'Digital': return Icons.computer;
      default: return Icons.category;
    }
  }

  void _logActivity() async {
    if (selectedActivity == null || _valueController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    try {
      setState(() => isSubmitting = true);
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
      
      // Show success dialog with suggestions
      _showSuccessDialog(carbonImpact, activity);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging activity: $e')),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void _showSuccessDialog(double carbonImpact, ActivityType activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 24),
            SizedBox(width: 8),
            Expanded(child: Text('Activity Logged Successfully!')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You generated ${carbonImpact.toStringAsFixed(2)} kg CO₂ for this activity.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'Tips to reduce your footprint:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              ...activity.tips.take(2).map((tip) => Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb, color: AppColors.warning, size: 16),
                    SizedBox(width: 8),
                    Expanded(child: Text(tip)),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Continue'),
          ),
        ],
      ),
    );
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
  bool isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final List<ActivityType> activities = CarbonFootprintDAO.getActivityTypesByCategory(widget.category);

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ResponsiveHelper.isMobile(context) ? double.infinity : 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: ResponsiveHelper.getAdaptivePadding(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                
                // Activity Selection
                _buildActivitySection(activities),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                
                // Value Input
                if (selectedActivity != null) ...[
                  _buildValueSection(),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                ],
                
                // Notes
                if (selectedActivity != null) ...[
                  _buildNotesSection(),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                ],
                
                // Action buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(_getCategoryIcon(widget.category), color: AppColors.primary, size: 24),
            SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
            Text(
              'Quick Log: ${widget.category}',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 20),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
        Text(
          'Quickly log your ${widget.category.toLowerCase()} activity. Select your activity and enter the amount.',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySection(List<ActivityType> activities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Activity',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
        DropdownButtonFormField<String>(
          value: selectedActivity,
          decoration: InputDecoration(
            labelText: 'Activity',
            border: OutlineInputBorder(),
            helperText: 'What ${widget.category.toLowerCase()} activity did you do?',
          ),
          items: activities.map((activity) => 
            DropdownMenuItem<String>(
              value: activity.name, 
              child: Row(
                children: [
                  Text(activity.icon),
                  SizedBox(width: 8),
                  Text(
                    activity.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            )
          ).toList(),
          onChanged: (value) {
            setState(() {
              selectedActivity = value;
              _valueController.clear();
            });
          },
        ),
        if (selectedActivity != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 4.0),
            child: Text(
              CarbonFootprintDAO.getActivityByName(selectedActivity!)?.description ?? '',
              style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
            ),
          ),
      ],
    );
  }

  Widget _buildValueSection() {
    final activity = CarbonFootprintDAO.getActivityByName(selectedActivity!);
    if (activity == null) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter Amount',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
        TextField(
          controller: _valueController,
          decoration: InputDecoration(
            labelText: 'Amount',
            suffixText: activity.unit,
            border: OutlineInputBorder(),
            helperText: _getValueHelperText(activity),
            prefixIcon: Icon(Icons.calculate),
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            setState(() {});
          },
        ),
        if (_valueController.text.isNotEmpty) ...[
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
          _buildCarbonPreview(),
        ],
      ],
    );
  }

  Widget _buildCarbonPreview() {
    try {
      final value = double.parse(_valueController.text);
      final carbonImpact = CarbonFootprintDAO.calculateCarbonImpact(selectedActivity!, value);
      
      return Container(
        padding: ResponsiveHelper.getAdaptivePadding(context) * 0.5,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primary, size: 16),
            SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            Expanded(
              child: Text(
                'Carbon impact: ${carbonImpact.toStringAsFixed(2)} kg CO₂',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return SizedBox.shrink();
    }
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes (Optional)',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
        TextField(
          controller: _notesController,
          decoration: InputDecoration(
            labelText: 'Additional details',
            border: OutlineInputBorder(),
            helperText: 'Any notes about this activity',
            prefixIcon: Icon(Icons.note),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ),
        SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
        Expanded(
          child: ElevatedButton(
            onPressed: isSubmitting ? null : _logActivity,
            child: isSubmitting 
                ? SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Log Activity'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
            ),
          ),
        ),
      ],
    );
  }

  String _getValueHelperText(ActivityType activity) {
    switch (activity.category) {
      case 'Transportation':
        return 'e.g., 12 km from home to work';
      case 'Energy':
        return 'e.g., 15 kWh of electricity used';
      case 'Food':
        return 'e.g., 0.5 kg of beef consumed';
      case 'Waste':
        return 'e.g., 2 kg of waste disposed';
      case 'Water':
        return 'e.g., 50 L of hot water used';
      case 'Digital':
        return 'e.g., 2 hours of video streaming';
      default:
        return 'Enter the amount of your activity';
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Transportation': return Icons.directions_car;
      case 'Energy': return Icons.electric_bolt;
      case 'Food': return Icons.restaurant;
      case 'Waste': return Icons.delete;
      case 'Water': return Icons.water_drop;
      case 'Digital': return Icons.computer;
      default: return Icons.category;
    }
  }

  void _logActivity() async {
    if (selectedActivity == null || _valueController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    try {
      setState(() => isSubmitting = true);
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
      
      // Show success dialog with suggestions
      _showSuccessDialog(carbonImpact, activity);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging activity: $e')),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void _showSuccessDialog(double carbonImpact, ActivityType activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 24),
            SizedBox(width: 8),
            Expanded(child: Text('Activity Logged Successfully!')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You generated ${carbonImpact.toStringAsFixed(2)} kg CO₂ for this activity.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'Tips to reduce your footprint:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              ...activity.tips.take(2).map((tip) => Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb, color: AppColors.warning, size: 16),
                    SizedBox(width: 8),
                    Expanded(child: Text(tip)),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Continue'),
          ),
        ],
      ),
    );
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