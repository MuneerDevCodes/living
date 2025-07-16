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
import 'package:fl_chart/fl_chart.dart';

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

  // Add a field to track the last activity impact
  CarbonFootprintEntry? lastLoggedEntry;

  int _pendingTabSwitch = 0; // 0: Overview, 1: Log Activity, etc.
  bool _highlightLastEntry = false;

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
    _tabController = TabController(length: 3, vsync: this); // Changed from 4 to 3
    _tabController.addListener(() {
      if (_tabController.index == 0) {
        setState(() => _highlightLastEntry = false);
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool switchToOverview = false, bool highlightLast = false}) async {
    try {
      setState(() => isLoading = true);
      userId = AuthService.getCurrentUserId();
      if (userId != null) {
        entries = await CarbonFootprintDAO.getUserEntries(userId!);
        goals = await CarbonFootprintDAO.getUserGoals(userId!);
        analytics = await CarbonFootprintDAO.getUserAnalytics(userId!);
        if (entries.isNotEmpty) {
          entries.sort((a, b) => b.date.compareTo(a.date));
          lastLoggedEntry = entries.first;
        } else {
          lastLoggedEntry = null;
        }
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
        setState(() {
          isLoading = false;
          if (switchToOverview) {
            _tabController.index = 0;
            _highlightLastEntry = highlightLast;
          }
        });
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
                        ], // Removed _buildGoalsTab()
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
        ], // Removed Goals tab
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Friendly explainer
          Card(
            color: AppColors.info.withOpacity(0.08),
            elevation: 0,
            margin: EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.eco, color: AppColors.primary, size: 32),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Track your daily activities and see your real environmental impact. Log activities, set goals, and watch your progress!',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (lastLoggedEntry != null)
            _buildLastActivityImpactCard(highlight: _highlightLastEntry),
          if (analytics == null)
            _buildEmptyState()
          else ...[
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
    final total = analytics!.categoryBreakdown.values.fold(0.0, (a, b) => a + b);
    final hasData = categories.isNotEmpty && total > 0;
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
            if (hasData) ...[
              SizedBox(
                height: 180,
                child: PieChart(
                  PieChartData(
                    sections: [
                      for (final entry in categories)
                        PieChartSectionData(
                          color: _getCategoryColor(entry.key),
                          value: entry.value,
                          title: '${((entry.value / total) * 100).toStringAsFixed(1)}%',
                          radius: 50,
                          titleStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                    ],
                    sectionsSpace: 2,
                    centerSpaceRadius: 32,
                  ),
                ),
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
            ] else ...[
              SizedBox(height: 32),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.insights, size: 48, color: AppColors.borderLight),
                    SizedBox(height: 12),
                    Text(
                      'No category data yet.',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Log activities to see your carbon breakdown!',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 13),
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
            ],
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
    // Personalized tip based on highest-impact category
    String personalizedTip = '';
    if (analytics != null && analytics!.categoryBreakdown.isNotEmpty) {
      final highest = analytics!.categoryBreakdown.entries.reduce((a, b) => a.value > b.value ? a : b);
      switch (highest.key) {
        case 'Transportation':
          personalizedTip = 'Your biggest impact is from Transportation. Try carpooling, using public transport, or walking for short trips!';
          break;
        case 'Energy':
          personalizedTip = 'Energy use is your top contributor. Switch to LED bulbs, unplug devices, and use energy-efficient appliances.';
          break;
        case 'Food':
          personalizedTip = 'Food is your largest source. Try more plant-based meals and reduce red meat consumption.';
          break;
        case 'Waste':
          personalizedTip = 'Waste is a major factor. Recycle, compost, and reduce single-use items.';
          break;
        case 'Water':
          personalizedTip = 'Water usage is high. Take shorter showers and fix leaks to save water and energy.';
          break;
        case 'Digital':
          personalizedTip = 'Digital activities add up. Stream in lower quality and delete unused files to reduce your digital footprint.';
          break;
        default:
          personalizedTip = 'Keep up the good work! Every small change helps the planet.';
      }
    }
    final tips = CarbonFootprintDAO.getGeneralTips().take(4).toList();
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
            if (personalizedTip.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.star, color: AppColors.primary, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        personalizedTip,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Friendly explainer
          Card(
            color: AppColors.success.withOpacity(0.08),
            elevation: 0,
            margin: EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.add_circle, color: AppColors.success, size: 32),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Log your daily activities here. Each log helps you understand and reduce your carbon footprint!',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (lastLoggedEntry != null) _buildLastActivityImpactCard(),
          _buildEducationalHeader(),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          _buildActivityLogForm(),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          _buildQuickLogButtons(),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          _buildBenefitsSection(),
        ],
      ),
    );
  }

  Widget _buildEducationalHeader() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, color: AppColors.primary, size: 24),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                Expanded(
                  child: Text(
                    'Understanding Carbon Footprint',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 20),
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            Text(
              'Your carbon footprint is the total amount of greenhouse gases (including carbon dioxide) that are generated by your actions. Every activity you do has an environmental impact.',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                color: AppColors.secondaryText,
                height: 1.4,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
            Container(
              padding: ResponsiveHelper.getAdaptivePadding(context) * 0.8,
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: AppColors.info, size: 20),
                      SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                      Expanded(
                        child: Text(
                          'Why Track Your Carbon Footprint?',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                            fontWeight: FontWeight.w600,
                            color: AppColors.info,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                  Text(
                    '• Identify your biggest impact areas\n'
                    '• Make informed lifestyle choices\n'
                    '• Track progress toward sustainability\n'
                    '• Contribute to climate action\n'
                    '• Save money through efficiency',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                      color: AppColors.secondaryText,
                      height: 1.4,
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
                Expanded(
                  child: Text(
                    'Log New Activity',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
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

  Widget _buildBenefitsSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Center-align the benefits section header
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.center,
                  spacing: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5,
                  children: [
                    Icon(Icons.emoji_events, color: AppColors.warning, size: 24),
                    Text(
                      'Benefits of Tracking Your Carbon Footprint',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                        fontWeight: FontWeight.bold,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            _buildBenefitItem(
              icon: Icons.trending_up,
              title: 'Track Progress',
              description: 'See how your carbon footprint changes over time and identify trends in your environmental impact.',
              color: AppColors.success,
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
            _buildBenefitItem(
              icon: Icons.lightbulb,
              title: 'Get Personalized Tips',
              description: 'Receive customized suggestions based on your activities to help reduce your environmental impact.',
              color: AppColors.warning,
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
            _buildBenefitItem(
              icon: Icons.savings,
              title: 'Save Money',
              description: 'Many carbon-reducing activities also save money through energy efficiency and reduced consumption.',
              color: AppColors.info,
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
            _buildBenefitItem(
              icon: Icons.group,
              title: 'Join the Movement',
              description: 'Be part of a global effort to combat climate change and inspire others to take action.',
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 400;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: ResponsiveHelper.getAdaptivePadding(context) * 0.8,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 24),
                    SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                    color: AppColors.secondaryText,
                    height: 1.3,
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                          color: AppColors.secondaryText,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAnalyticsTab() {
    // Add friendly explainer at the top
    return SingleChildScrollView(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: AppColors.warning.withOpacity(0.08),
            elevation: 0,
            margin: EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.analytics, color: AppColors.warning, size: 32),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'See your trends and breakdowns. Analytics help you spot patterns and improve your sustainability journey.',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          analytics == null ? _buildEmptyState() : _buildAnalyticsTabContent(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTabContent() {
    final highestCategory = analytics!.categoryBreakdown.entries.isNotEmpty
        ? analytics!.categoryBreakdown.entries.reduce((a, b) => a.value > b.value ? a : b)
        : null;
    final lowestCategory = analytics!.categoryBreakdown.entries.isNotEmpty
        ? analytics!.categoryBreakdown.entries.reduce((a, b) => a.value < b.value ? a : b)
        : null;
    final highestDay = analytics!.weeklyTrend.entries.isNotEmpty
        ? analytics!.weeklyTrend.entries.reduce((a, b) => a.value > b.value ? a : b)
        : null;
    final trendData = analytics!.weeklyTrend.entries.toList();
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
          // Category Breakdown (with Pie Chart)
          _buildCategoryBreakdownCard(),
          SizedBox(height: 24),
          // Weekly Trends (with Bar Chart)
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
                  SizedBox(
                    height: 180,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: trendData.map((e) => e.value).fold(0.0, (a, b) => a > b ? a : b) + 2,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= trendData.length) return Container();
                                return Text(trendData[idx].key, style: TextStyle(fontSize: 10));
                              },
                              reservedSize: 32,
                            ),
                          ),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          for (int i = 0; i < trendData.length; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: trendData[i].value,
                                  color: AppColors.info,
                                  width: 18,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
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
            'Start by logging your first activity! This will unlock your dashboard and insights.',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              color: AppColors.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          ElevatedButton.icon(
            onPressed: _showActivityLogDialog,
            icon: Icon(Icons.add),
            label: Text('Log Activity'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showActivityLogDialog() {
    FocusScope.of(context).unfocus();
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => ActivityLogDialog(
            onActivityLogged: () {
              Navigator.pop(context);
              _loadData(switchToOverview: true, highlightLast: true);
            },
          ),
        );
      }
    });
  }

  void _showCategoryActivityDialog(String category) {
    FocusScope.of(context).unfocus();
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => CategoryActivityDialog(
            category: category,
            onActivityLogged: () {
              Navigator.pop(context);
              _loadData(switchToOverview: true, highlightLast: true);
            },
          ),
        );
      }
    });
  }

  Widget _buildLastActivityImpactCard({bool highlight = false}) {
    final entry = lastLoggedEntry;
    if (entry == null) return SizedBox.shrink();
    return Card(
      color: highlight ? AppColors.success.withOpacity(0.25) : AppColors.success.withOpacity(0.08),
      elevation: highlight ? 8 : 4,
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context)),
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Row(
          children: [
            Icon(Icons.flash_on, color: AppColors.success, size: 32),
            SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last Activity Logged',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${entry.activityType} • ${entry.value} ${entry.unit}',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      color: AppColors.primaryText,
                    ),
                  ),
                  Text(
                    '+${entry.carbonImpact.toStringAsFixed(2)} kg CO₂',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                  if (entry.notes != null && entry.notes!.isNotEmpty)
                    Text(
                      'Notes: ${entry.notes}',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                        color: AppColors.secondaryText,
                        fontStyle: FontStyle.italic,
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
  int currentStep = 1;

  @override
  Widget build(BuildContext context) {
    final categories = CarbonFootprintDAO.getAllCategories();
    final List<ActivityType> activities = selectedCategory != null 
        ? CarbonFootprintDAO.getActivityTypesByCategory(selectedCategory!)
        : <ActivityType>[];

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ResponsiveHelper.isMobile(context) ? double.infinity : 700,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: ResponsiveHelper.getAdaptivePadding(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced Header with Benefits
                _buildEnhancedHeader(),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                
                // Progress Indicator
                _buildProgressIndicator(),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                
                // Step 1: Category Selection with Educational Content
                if (currentStep >= 1) ...[
                  _buildCategorySection(categories),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                ],
                
                // Step 2: Activity Selection with Impact Information
                if (currentStep >= 2 && selectedCategory != null) ...[
                  _buildActivitySection(activities),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                ],
                
                // Step 3: Value Input with Real-time Impact Preview
                if (currentStep >= 3 && selectedActivity != null) ...[
                  _buildValueSection(),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                ],
                
                // Step 4: Optional fields with Context
                if (currentStep >= 4 && selectedActivity != null) ...[
                  _buildOptionalFields(),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                ],
                
                // Step 5: Summary and Impact Analysis
                if (currentStep >= 5 && selectedActivity != null && _valueController.text.isNotEmpty) ...[
                  _buildImpactSummary(),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                ],
                
                // Action buttons with Navigation
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.eco, color: AppColors.primary, size: 28),
            SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
            Expanded(
              child: Text(
                'Track Your Carbon Impact',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 22),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
        Container(
          padding: ResponsiveHelper.getAdaptivePadding(context) * 0.8,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb, color: AppColors.warning, size: 20),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                  Expanded(
                    child: Text(
                      'Why Track Your Carbon Footprint?',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
              Text(
                '• Understand your environmental impact\n'
                '• Identify areas for improvement\n'
                '• Track progress toward sustainability goals\n'
                '• Make informed lifestyle choices\n'
                '• Contribute to climate action',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  color: AppColors.secondaryText,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    final steps = ['Category', 'Activity', 'Amount', 'Details', 'Review'];
    final currentStepIndex = currentStep - 1;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step $currentStep of ${steps.length}',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isCompleted = index < currentStepIndex;
            final isCurrent = index == currentStepIndex;
            
            return Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCompleted 
                          ? AppColors.success 
                          : isCurrent 
                              ? AppColors.primary 
                              : AppColors.borderLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCompleted ? Icons.check : Icons.circle,
                      color: AppColors.white,
                      size: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      step,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? AppColors.primary : AppColors.secondaryText,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
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
            Icon(Icons.category, color: AppColors.info, size: 24),
            SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            Text(
              'Step 1: Choose Activity Category',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
        Text(
          'Select the category that best describes your activity. Each category has different environmental impacts and reduction opportunities.',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
            color: AppColors.secondaryText,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
        
        // Category Cards with Impact Information
        Wrap(
          spacing: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5,
          runSpacing: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5,
          children: categories.map((category) => _buildCategoryCard(category)).toList(),
        ),
        
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
        DropdownButtonFormField<String>(
          value: selectedCategory,
          decoration: InputDecoration(
            labelText: 'Or select from dropdown',
            border: OutlineInputBorder(),
            helperText: 'What type of activity are you logging?',
          ),
          items: categories.map((category) => 
            DropdownMenuItem(
              value: category, 
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getCategoryIcon(category), size: 16),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      category,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          ).toList(),
          onChanged: (value) {
            setState(() {
              selectedCategory = value;
              selectedActivity = null;
              _valueController.clear();
              if (value != null) currentStep = 2;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCategoryCard(String category) {
    final isSelected = selectedCategory == category;
    final impactInfo = _getCategoryImpactInfo(category);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
          selectedActivity = null;
          _valueController.clear();
          currentStep = 2;
        });
      },
      child: Container(
        constraints: BoxConstraints(
          minWidth: ResponsiveHelper.isMobile(context) ? double.infinity : 200,
          maxWidth: ResponsiveHelper.isMobile(context) ? double.infinity : 200,
        ),
        padding: ResponsiveHelper.getAdaptivePadding(context) * 0.8,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            )
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  _getCategoryIcon(category),
                  color: isSelected ? AppColors.white : AppColors.primary,
                  size: 24,
                ),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                Flexible(
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.white : AppColors.primaryText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            Flexible(
              child: Text(
                impactInfo,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                  color: isSelected ? AppColors.white.withOpacity(0.9) : AppColors.secondaryText,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryImpactInfo(String category) {
    switch (category) {
      case 'Transportation':
        return 'Largest contributor to personal carbon footprint';
      case 'Energy':
        return 'Home energy use and electricity consumption';
      case 'Food':
        return 'Dietary choices and food production impact';
      case 'Waste':
        return 'Landfill emissions and recycling benefits';
      case 'Water':
        return 'Water heating and consumption impact';
      case 'Digital':
        return 'Internet and technology carbon footprint';
      default:
        return 'Track your environmental impact';
    }
  }

  Widget _buildActivitySection(List<ActivityType> activities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.list, color: AppColors.info, size: 24),
            SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            Text(
              'Step 2: Select Specific Activity',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
        Text(
          'Choose the specific activity you performed. Each activity has different carbon factors and reduction tips.',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
            color: AppColors.secondaryText,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
        
        // Activity Cards with Impact Comparison
        Column(
          children: activities.map((activity) => _buildActivityCard(activity)).toList(),
        ),
        
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
        DropdownButtonFormField<String>(
          value: selectedActivity,
          decoration: InputDecoration(
            labelText: 'Or select from dropdown',
            border: OutlineInputBorder(),
            helperText: 'What exactly did you do?',
          ),
          items: activities.map((activity) =>
            DropdownMenuItem<String>(
              value: activity.name,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(activity.icon, style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      activity.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            )
          ).toList(),
          onChanged: (value) {
            setState(() {
              selectedActivity = value;
              _valueController.clear();
              if (value != null) currentStep = 3;
            });
          },
        ),
      ],
    );
  }

  Widget _buildActivityCard(ActivityType activity) {
    final isSelected = selectedActivity == activity.name;
    final carbonFactor = activity.carbonFactor;
    final impactLevel = _getImpactLevel(carbonFactor);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedActivity = activity.name;
          _valueController.clear();
          currentStep = 3;
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
        padding: ResponsiveHelper.getAdaptivePadding(context) * 0.8,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            )
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  activity.icon,
                  style: TextStyle(fontSize: 24),
                ),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                Expanded(
                  child: Text(
                    activity.name,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.white : AppColors.primaryText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.white.withOpacity(0.2) : impactLevel.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    impactLevel.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.white : impactLevel.color,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            Flexible(
              child: Text(
                activity.description,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                  color: isSelected ? AppColors.white.withOpacity(0.9) : AppColors.secondaryText,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            if (isSelected) ...[
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
              Container(
                padding: ResponsiveHelper.getAdaptivePadding(context) * 0.5,
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Tips to reduce impact:',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    ...activity.tips.take(2).map((tip) => Padding(
                      padding: EdgeInsets.only(bottom: 2),
                      child: Text(
                        '• $tip',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 11),
                          color: AppColors.white.withOpacity(0.9),
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  ImpactLevel _getImpactLevel(double carbonFactor) {
    if (carbonFactor <= 0.1) return ImpactLevel('Low', AppColors.success);
    if (carbonFactor <= 1.0) return ImpactLevel('Medium', AppColors.warning);
    if (carbonFactor <= 5.0) return ImpactLevel('High', AppColors.error);
    return ImpactLevel('Very High', AppColors.error);
  }

  Widget _buildValueSection() {
    final activity = CarbonFootprintDAO.getActivityByName(selectedActivity!);
    if (activity == null) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.input, color: AppColors.info, size: 24),
            SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            Text(
              'Step 3: Enter Activity Details',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
        Text(
          'Enter the amount of your activity. This helps calculate your carbon footprint accurately.',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
            color: AppColors.secondaryText,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
        
        // Enhanced Input with Examples
        Container(
          padding: ResponsiveHelper.getAdaptivePadding(context) * 0.8,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📊 Activity: ${activity.name}',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
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
                  setState(() {
                    if (value.isNotEmpty) currentStep = 4;
                  });
                },
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
              Text(
                '💡 Examples:',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                _getExamplesText(activity),
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
        
        if (_valueController.text.isNotEmpty) ...[
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
          _buildCarbonPreview(),
        ],
      ],
    );
  }

  String _getExamplesText(ActivityType activity) {
    switch (activity.category) {
      case 'Transportation':
        return '• 12 km (home to work)\n• 5 km (grocery shopping)\n• 25 km (weekend trip)';
      case 'Energy':
        return '• 15 kWh (daily usage)\n• 100 kWh (monthly bill)\n• 5 kWh (appliance use)';
      case 'Food':
        return '• 0.5 kg (beef meal)\n• 1 kg (weekly groceries)\n• 0.2 kg (single serving)';
      case 'Waste':
        return '• 2 kg (daily waste)\n• 10 kg (weekly trash)\n• 0.5 kg (food scraps)';
      case 'Water':
        return '• 50 L (shower)\n• 100 L (bath)\n• 10 L (dishwashing)';
      case 'Digital':
        return '• 2 hours (streaming)\n• 5 GB (data usage)\n• 1 hour (video call)';
      default:
        return 'Enter the amount based on your activity';
    }
  }

  Widget _buildCarbonPreview() {
    try {
      final value = double.parse(_valueController.text);
      final carbonImpact = CarbonFootprintDAO.calculateCarbonImpact(selectedActivity!, value);
      final activity = CarbonFootprintDAO.getActivityByName(selectedActivity!);
      
      return Container(
        padding: ResponsiveHelper.getAdaptivePadding(context) * 0.8,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                Text(
                  'Carbon Impact Preview',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${carbonImpact.toStringAsFixed(2)} kg CO₂',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 24),
                          fontWeight: FontWeight.bold,
                          color: carbonImpact > 0 ? AppColors.error : AppColors.success,
                        ),
                      ),
                      Text(
                        'Generated for this activity',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: ResponsiveHelper.getAdaptivePadding(context) * 0.5,
                  decoration: BoxDecoration(
                    color: _getImpactLevel(carbonImpact).color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getImpactLevel(carbonImpact).label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getImpactLevel(carbonImpact).color,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            Text(
              _getImpactComparison(carbonImpact),
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return SizedBox.shrink();
    }
  }

  String _getImpactComparison(double carbonImpact) {
    if (carbonImpact <= 0) {
      return '✅ This activity saves carbon emissions!';
    } else if (carbonImpact <= 1.0) {
      return '🌱 Low impact - equivalent to ${(carbonImpact * 100).toStringAsFixed(0)}g of CO₂';
    } else if (carbonImpact <= 5.0) {
      return '⚠️ Medium impact - equivalent to ${(carbonImpact * 100).toStringAsFixed(0)}g of CO₂';
    } else {
      return '🚨 High impact - equivalent to ${(carbonImpact * 100).toStringAsFixed(0)}g of CO₂';
    }
  }

  Widget _buildOptionalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.notes, color: AppColors.info, size: 24),
            SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            Text(
              'Step 4: Additional Details (Optional)',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
        Text(
          'Add location and notes to help you remember and track your activities better. This information helps you identify patterns and make better choices.',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
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

  Widget _buildImpactSummary() {
    try {
      final value = double.parse(_valueController.text);
      final carbonImpact = CarbonFootprintDAO.calculateCarbonImpact(selectedActivity!, value);
      final activity = CarbonFootprintDAO.getActivityByName(selectedActivity!);
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize, color: AppColors.info, size: 24),
              SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
              Text(
                'Step 5: Review Your Entry',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
          Container(
            padding: ResponsiveHelper.getAdaptivePadding(context) * 0.8,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📋 Activity Summary',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                _buildSummaryRow('Activity', activity?.name ?? ''),
                _buildSummaryRow('Category', activity?.category ?? ''),
                _buildSummaryRow('Amount', '${value.toStringAsFixed(1)} ${activity?.unit ?? ''}'),
                _buildSummaryRow('Carbon Impact', '${carbonImpact.toStringAsFixed(2)} kg CO₂'),
                if (_locationController.text.isNotEmpty)
                  _buildSummaryRow('Location', _locationController.text),
                if (_notesController.text.isNotEmpty)
                  _buildSummaryRow('Notes', _notesController.text),
              ],
            ),
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
          Container(
            padding: ResponsiveHelper.getAdaptivePadding(context) * 0.8,
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 What happens next?',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                Text(
                  '• Your carbon footprint will be updated\n'
                  '• You\'ll see trends in your analytics\n'
                  '• Get personalized tips for reduction\n'
                  '• Track progress toward your goals\n'
                  '• Compare with sustainable targets',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                    color: AppColors.secondaryText,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } catch (e) {
      return SizedBox.shrink();
    }
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                color: AppColors.primaryText,
              ),
            ),
          ),
        ],
      ),
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
      
      // Show enhanced success dialog with educational content
      _showEnhancedSuccessDialog(carbonImpact, activity);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging activity: $e')),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void _showEnhancedSuccessDialog(double carbonImpact, ActivityType activity) {
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
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📊 Your Impact',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'You generated ${carbonImpact.toStringAsFixed(2)} kg CO₂ for this activity.',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getImpactContext(carbonImpact),
                      style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                '💡 Tips to reduce your footprint:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              ...activity.tips.take(3).map((tip) => Padding(
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
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎯 Next Steps',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Check your analytics to see trends\n'
                      '• Set carbon reduction goals\n'
                      '• Explore sustainable alternatives\n'
                      '• Share your progress with others',
                      style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
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

  String _getImpactContext(double carbonImpact) {
    if (carbonImpact <= 0) {
      return 'Great! This activity helps reduce emissions.';
    } else if (carbonImpact <= 1.0) {
      return 'This is a relatively low-impact activity.';
    } else if (carbonImpact <= 5.0) {
      return 'Consider alternatives to reduce your impact.';
    } else {
      return 'This is a high-impact activity. Look for sustainable alternatives.';
    }
  }
}

// Helper class for impact levels
class ImpactLevel {
  final String label;
  final Color color;
  
  ImpactLevel(this.label, this.color);
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
          maxWidth: ResponsiveHelper.isMobile(context) ? double.infinity : 650,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: ResponsiveHelper.getAdaptivePadding(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced Header with Category Benefits
                _buildEnhancedHeader(),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                
                // Activity Selection with Impact Cards
                _buildActivitySection(activities),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                
                // Value Input with Real-time Preview
                if (selectedActivity != null) ...[
                  _buildValueSection(),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                ],
                
                // Notes with Context
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

  Widget _buildEnhancedHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(_getCategoryIcon(widget.category), color: AppColors.primary, size: 28),
            SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
            Expanded(
              child: Text(
                'Quick Log: ${widget.category}',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 22),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
        Container(
          padding: ResponsiveHelper.getAdaptivePadding(context) * 0.8,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.flash_on, color: AppColors.warning, size: 20),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                  Text(
                    'Quick ${widget.category} Tracking',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
              Text(
                _getCategoryDescription(widget.category),
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  color: AppColors.secondaryText,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getCategoryDescription(String category) {
    switch (category) {
      case 'Transportation':
        return 'Track your travel impact and discover sustainable alternatives. Transportation is often the largest contributor to personal carbon footprints.';
      case 'Energy':
        return 'Monitor your home energy consumption and find ways to reduce electricity and heating costs while helping the environment.';
      case 'Food':
        return 'Understand how your dietary choices impact the environment. Food production accounts for a significant portion of global emissions.';
      case 'Waste':
        return 'Track your waste generation and recycling efforts. Proper waste management can significantly reduce your environmental impact.';
      case 'Water':
        return 'Monitor water usage and heating. Water treatment and heating contribute to your carbon footprint.';
      case 'Digital':
        return 'Track your digital carbon footprint. Internet usage, streaming, and data centers all consume energy.';
      default:
        return 'Track your environmental impact in this category.';
    }
  }

  Widget _buildActivitySection(List<ActivityType> activities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.list, color: AppColors.info, size: 24),
            SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            Text(
              'Select Your Activity',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
        Text(
          'Choose the specific ${widget.category.toLowerCase()} activity you performed. Each has different environmental impacts.',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
            color: AppColors.secondaryText,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
        
        // Activity Cards with Impact Information
        Column(
          children: activities.map((activity) => _buildActivityCard(activity)).toList(),
        ),
        
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
        DropdownButtonFormField<String>(
          value: selectedActivity,
          decoration: InputDecoration(
            labelText: 'Or select from dropdown',
            border: OutlineInputBorder(),
            helperText: 'What ${widget.category.toLowerCase()} activity did you do?',
          ),
          items: activities.map((activity) => 
            DropdownMenuItem<String>(
              value: activity.name, 
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(activity.icon, style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      activity.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
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
      ],
    );
  }

  Widget _buildActivityCard(ActivityType activity) {
    final isSelected = selectedActivity == activity.name;
    final impactLevel = _getImpactLevel(activity.carbonFactor);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedActivity = activity.name;
          _valueController.clear();
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
        padding: ResponsiveHelper.getAdaptivePadding(context) * 0.8,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            )
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  activity.icon,
                  style: TextStyle(fontSize: 24),
                ),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                Expanded(
                  child: Text(
                    activity.name,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.white : AppColors.primaryText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.white.withOpacity(0.2) : impactLevel.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    impactLevel.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.white : impactLevel.color,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            Flexible(
              child: Text(
                activity.description,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                  color: isSelected ? AppColors.white.withOpacity(0.9) : AppColors.secondaryText,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            if (isSelected) ...[
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
              Container(
                padding: ResponsiveHelper.getAdaptivePadding(context) * 0.5,
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Quick tips:',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    ...activity.tips.take(2).map((tip) => Padding(
                      padding: EdgeInsets.only(bottom: 2),
                      child: Text(
                        '• $tip',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 11),
                          color: AppColors.white.withOpacity(0.9),
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  ImpactLevel _getImpactLevel(double carbonFactor) {
    if (carbonFactor <= 0.1) return ImpactLevel('Low', AppColors.success);
    if (carbonFactor <= 1.0) return ImpactLevel('Medium', AppColors.warning);
    if (carbonFactor <= 5.0) return ImpactLevel('High', AppColors.error);
    return ImpactLevel('Very High', AppColors.error);
  }

  Widget _buildValueSection() {
    final activity = CarbonFootprintDAO.getActivityByName(selectedActivity!);
    if (activity == null) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.input, color: AppColors.info, size: 24),
            SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            Text(
              'Enter Activity Amount',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
        Text(
          'Enter the amount of your activity to calculate the carbon impact.',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
            color: AppColors.secondaryText,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
        
        // Enhanced Input with Examples
        Container(
          padding: ResponsiveHelper.getAdaptivePadding(context) * 0.8,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📊 Activity: ${activity.name}',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
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
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
              Text(
                '💡 Examples:',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                _getExamplesText(activity),
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
        
        if (_valueController.text.isNotEmpty) ...[
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
          _buildCarbonPreview(),
        ],
      ],
    );
  }

  String _getExamplesText(ActivityType activity) {
    switch (activity.category) {
      case 'Transportation':
        return '• 12 km (home to work)\n• 5 km (grocery shopping)\n• 25 km (weekend trip)';
      case 'Energy':
        return '• 15 kWh (daily usage)\n• 100 kWh (monthly bill)\n• 5 kWh (appliance use)';
      case 'Food':
        return '• 0.5 kg (beef meal)\n• 1 kg (weekly groceries)\n• 0.2 kg (single serving)';
      case 'Waste':
        return '• 2 kg (daily waste)\n• 10 kg (weekly trash)\n• 0.5 kg (food scraps)';
      case 'Water':
        return '• 50 L (shower)\n• 100 L (bath)\n• 10 L (dishwashing)';
      case 'Digital':
        return '• 2 hours (streaming)\n• 5 GB (data usage)\n• 1 hour (video call)';
      default:
        return 'Enter the amount based on your activity';
    }
  }

  Widget _buildCarbonPreview() {
    try {
      final value = double.parse(_valueController.text);
      final carbonImpact = CarbonFootprintDAO.calculateCarbonImpact(selectedActivity!, value);
      
      return Container(
        padding: ResponsiveHelper.getAdaptivePadding(context) * 0.8,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                Text(
                  'Carbon Impact Preview',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${carbonImpact.toStringAsFixed(2)} kg CO₂',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 24),
                          fontWeight: FontWeight.bold,
                          color: carbonImpact > 0 ? AppColors.error : AppColors.success,
                        ),
                      ),
                      Text(
                        'Generated for this activity',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: ResponsiveHelper.getAdaptivePadding(context) * 0.5,
                  decoration: BoxDecoration(
                    color: _getImpactLevel(carbonImpact).color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getImpactLevel(carbonImpact).label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getImpactLevel(carbonImpact).color,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            Text(
              _getImpactComparison(carbonImpact),
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return SizedBox.shrink();
    }
  }

  String _getImpactComparison(double carbonImpact) {
    if (carbonImpact <= 0) {
      return '✅ This activity saves carbon emissions!';
    } else if (carbonImpact <= 1.0) {
      return '🌱 Low impact - equivalent to ${(carbonImpact * 100).toStringAsFixed(0)}g of CO₂';
    } else if (carbonImpact <= 5.0) {
      return '⚠️ Medium impact - equivalent to ${(carbonImpact * 100).toStringAsFixed(0)}g of CO₂';
    } else {
      return '🚨 High impact - equivalent to ${(carbonImpact * 100).toStringAsFixed(0)}g of CO₂';
    }
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.notes, color: AppColors.info, size: 24),
            SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            Text(
              'Additional Notes (Optional)',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
        Text(
          'Add notes to help you remember details about this activity. This can help you identify patterns and make better choices.',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
            color: AppColors.secondaryText,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
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
      
      // Show enhanced success dialog with educational content
      _showEnhancedSuccessDialog(carbonImpact, activity);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging activity: $e')),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void _showEnhancedSuccessDialog(double carbonImpact, ActivityType activity) {
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
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📊 Your Impact',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'You generated ${carbonImpact.toStringAsFixed(2)} kg CO₂ for this activity.',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getImpactContext(carbonImpact),
                      style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                '💡 Tips to reduce your footprint:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              ...activity.tips.take(3).map((tip) => Padding(
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
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎯 Next Steps',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Check your analytics to see trends\n'
                      '• Set carbon reduction goals\n'
                      '• Explore sustainable alternatives\n'
                      '• Share your progress with others',
                      style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
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

  String _getImpactContext(double carbonImpact) {
    if (carbonImpact <= 0) {
      return 'Great! This activity helps reduce emissions.';
    } else if (carbonImpact <= 1.0) {
      return 'This is a relatively low-impact activity.';
    } else if (carbonImpact <= 5.0) {
      return 'Consider alternatives to reduce your impact.';
    } else {
      return 'This is a high-impact activity. Look for sustainable alternatives.';
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
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final categories = CarbonFootprintDAO.getAllCategories();

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.flag, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Add Carbon Goal'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                'Set a weekly goal to reduce your carbon footprint. Fill in the details below. Each field has a hint to help you!',
                style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
              ),
            ),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Goal Title',
                hintText: 'e.g., Reduce my weekly CO₂',
                helperText: "Give your goal a name you'll recognize.",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'e.g., I want to keep my carbon emissions under 10 kg this week.',
                helperText: "Describe your goal and why it's important to you.",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                helperText: 'Choose the main area you want to focus on.',
                border: OutlineInputBorder(),
              ),
              items: categories.map((category) => 
                DropdownMenuItem(value: category, child: Text(category))
              ).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
            ),
            SizedBox(height: 12),
            TextField(
              controller: _targetController,
              decoration: InputDecoration(
                labelText: 'Target Value (kg CO₂)',
                hintText: 'e.g., 10',
                helperText: 'Set your weekly CO₂ target in kilograms (kg). Lower is better!',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          startDate = date;
                        });
                      }
                    },
                    icon: Icon(Icons.calendar_today, size: 16),
                    label: Text(startDate == null ? 'Start Date' : '${startDate!.toLocal()}'.split(' ')[0]),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: endDate ?? DateTime.now().add(Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          endDate = date;
                        });
                      }
                    },
                    icon: Icon(Icons.calendar_today, size: 16),
                    label: Text(endDate == null ? 'End Date' : '${endDate!.toLocal()}'.split(' ')[0]),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Pick the week you want this goal to apply to.',
                style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
              ),
            ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  errorMessage!,
                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                ),
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
          onPressed: _validateAndAddGoal,
          child: Text('Add Goal'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: AppColors.white,
          ),
        ),
      ],
    );
  }

  void _validateAndAddGoal() async {
    setState(() => errorMessage = null);
    if (_titleController.text.isEmpty) {
      setState(() => errorMessage = 'Please enter a goal title.');
      return;
    }
    if (_descriptionController.text.isEmpty) {
      setState(() => errorMessage = 'Please enter a description.');
      return;
    }
    if (selectedCategory == null) {
      setState(() => errorMessage = 'Please select a category.');
      return;
    }
    if (_targetController.text.isEmpty || double.tryParse(_targetController.text) == null) {
      setState(() => errorMessage = 'Please enter a valid target value.');
      return;
    }
    if (startDate == null || endDate == null) {
      setState(() => errorMessage = 'Please select both start and end dates.');
      return;
    }
    if (endDate!.isBefore(startDate!)) {
      setState(() => errorMessage = 'End date must be after start date.');
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
      setState(() => errorMessage = 'Error adding goal: $e');
    }
  }
} 