import 'package:flutter/material.dart';
import 'package:living/models/progress_dashboard_model.dart';
import 'package:living/services/progress_dashboard_dao.dart';
import 'package:living/services/carbon_footprint_dao.dart';
import 'package:living/services/waste_tracker_dao.dart';
import 'package:living/services/energy_tip_dao.dart';
import 'package:living/services/challenge_dao.dart';
import 'package:living/services/auth_helper.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/widgets/alert_error.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ProgressDashboardPage extends StatefulWidget {
  const ProgressDashboardPage({super.key});

  @override
  State<ProgressDashboardPage> createState() => _ProgressDashboardPageState();
}

class _ProgressDashboardPageState extends State<ProgressDashboardPage> {
  List<UserProgress> progress = [];
  bool isLoading = true;
  String? userId;

  // Dynamic data from different services
  double _carbonFootprint = 0.0;
  double _wasteReduction = 0.0;
  double _energySavings = 0.0;
  int _challengesCompleted = 0;
  
  // Chart data for trends
  List<double> _carbonTrend = [];
  List<double> _wasteTrend = [];
  List<double> _energyTrend = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when returning to this page
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);
      userId = AuthService.getCurrentUserId();
      if (userId != null) {
        // Load progress dashboard data
        progress = await ProgressDashboardDAO.getUserProgress(userId!);
        
        // Load dynamic data from respective services
        await _loadCarbonFootprintData();
        await _loadWasteReductionData();
        await _loadEnergySavingsData();
        await _loadChallengesData();
      }
    } catch (e) {
      if (mounted) {
        print('Error loading progress data: $e');
        setState(() {
          progress = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // Load carbon footprint data from carbon footprint service
  Future<void> _loadCarbonFootprintData() async {
    try {
      if (userId != null) {
        final entries = await CarbonFootprintDAO.getUserEntries(userId!);
        final analytics = await CarbonFootprintDAO.getUserAnalytics(userId!);
        
        if (analytics != null) {
          setState(() {
            _carbonFootprint = analytics.weeklyAverage;
          });
        } else if (entries.isNotEmpty) {
          // Calculate average from recent entries
          final recentEntries = entries.take(7).toList();
          final totalFootprint = recentEntries.fold(0.0, (sum, e) => sum + e.carbonImpact);
          setState(() {
            _carbonFootprint = totalFootprint / recentEntries.length;
          });
        }
        
        // Generate trend data for chart
        _generateCarbonTrend(entries);
      }
    } catch (e) {
      print('Error loading carbon footprint data: $e');
    }
  }

  // Load waste reduction data from waste tracker service
  Future<void> _loadWasteReductionData() async {
    try {
      if (userId != null) {
        final entries = await WasteTrackerDAO.getUserWasteEntries(userId!);
        
        // Calculate total waste reduced (entries with recycling, composting, donation)
        final sustainableDisposal = entries.where((e) => 
          e.disposalMethod.toLowerCase() == 'recycling' ||
          e.disposalMethod.toLowerCase() == 'composting' ||
          e.disposalMethod.toLowerCase() == 'donation'
        ).toList();
        
        final totalReduced = sustainableDisposal.fold(0.0, (sum, e) => sum + e.amount);
        setState(() {
          _wasteReduction = totalReduced;
        });
        
        // Generate trend data for chart
        _generateWasteTrend(entries);
      }
    } catch (e) {
      print('Error loading waste reduction data: $e');
    }
  }

  // Load energy savings data from energy tips service
  Future<void> _loadEnergySavingsData() async {
    try {
      if (userId != null) {
        final tips = await EnergyTipDAO.getAllEnergyTips();
        
        // Calculate total energy savings from all tips (as a baseline)
        final totalSavings = tips.fold(0.0, (sum, tip) => sum + tip.potentialSavings);
        
        setState(() {
          _energySavings = totalSavings;
        });
        
        // Generate trend data for chart
        _generateEnergyTrend(tips);
      }
    } catch (e) {
      print('Error loading energy savings data: $e');
    }
  }

  // Load challenges data from challenges service
  Future<void> _loadChallengesData() async {
    try {
      if (userId != null) {
        final challenges = await ChallengeDAO.getUserChallenges(userId!);
        
        // Count completed challenges
        final completedChallenges = challenges.where((c) => c.isCompleted).length;
        
        setState(() {
          _challengesCompleted = completedChallenges;
        });
      }
    } catch (e) {
      print('Error loading challenges data: $e');
    }
  }

  // Generate trend data for carbon footprint
  void _generateCarbonTrend(List<dynamic> entries) {
    _carbonTrend.clear();
    if (entries.isNotEmpty) {
      // Take last 7 entries and create trend
      final recentEntries = entries.take(7).toList();
      for (int i = 0; i < 7; i++) {
        if (i < recentEntries.length) {
          _carbonTrend.add(recentEntries[i].carbonImpact);
        } else {
          _carbonTrend.add(0.0);
        }
      }
    } else {
      // Generate sample trend based on current value
      for (int i = 0; i < 7; i++) {
        final progress = (i + 1) / 7.0;
        _carbonTrend.add(_carbonFootprint * progress);
      }
    }
  }

  // Generate trend data for waste reduction
  void _generateWasteTrend(List<dynamic> entries) {
    _wasteTrend.clear();
    if (entries.isNotEmpty) {
      // Take last 7 entries and create trend
      final recentEntries = entries.take(7).toList();
      for (int i = 0; i < 7; i++) {
        if (i < recentEntries.length) {
          _wasteTrend.add(recentEntries[i].amount);
        } else {
          _wasteTrend.add(0.0);
        }
      }
    } else {
      // Generate sample trend based on current value
      for (int i = 0; i < 7; i++) {
        final progress = (i + 1) / 7.0;
        _wasteTrend.add(_wasteReduction * progress);
      }
    }
  }

  // Generate trend data for energy savings
  void _generateEnergyTrend(List<dynamic> entries) {
    _energyTrend.clear();
    if (entries.isNotEmpty) {
      // Take last 7 entries and create trend
      final recentEntries = entries.take(7).toList();
      for (int i = 0; i < 7; i++) {
        if (i < recentEntries.length) {
          _energyTrend.add(recentEntries[i].potentialSavings);
        } else {
          _energyTrend.add(0.0);
        }
      }
    } else {
      // Generate sample trend based on current value
      for (int i = 0; i < 7; i++) {
        final progress = (i + 1) / 7.0;
        _energyTrend.add(_energySavings * progress);
      }
    }
  }

  // Calculate maximum Y value for chart
  double _calculateMaxY() {
    final allValues = [..._carbonTrend, ..._wasteTrend, ..._energyTrend];
    if (allValues.isEmpty) return 12.0; // Default max
    
    final maxValue = allValues.reduce((a, b) => a > b ? a : b);
    return maxValue > 0 ? maxValue * 1.2 : 12.0; // Add 20% padding
  }

  // Updated getters to use dynamic data
  double get averageCarbonFootprint => _carbonFootprint;

  double get averageWasteReduction => _wasteReduction;

  double get averageEnergySavings => _energySavings;

  int get totalChallengesCompleted => _challengesCompleted;

  int get totalPoints {
    if (progress.isEmpty) return 0;
    return progress.fold(0, (sum, p) => sum + p.totalPoints);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Header.buildDrawer(context),
      body: Column(
        children: [
          // Removed the green header/banner here
          Expanded(
            child: Stack(
              children: [
                if (isLoading) const Positioned.fill(child: Loader()),
                Column(
                  children: [
                    Expanded(
                      child: _buildOverviewTab(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Motivational Tip at the bottom
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.7,
              horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 1.5,
            ),
            child: _buildMotivationalTip(),
          ),
          Footer(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          children: [
            _buildWelcomeSection(),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            _buildSummaryCards(),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            _buildBadgeRow(),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            _buildProgressChart(),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            _buildRecentProgress(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.1), AppColors.success.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco, color: AppColors.primary, size: 28),
              SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
              Expanded(
                child: Text(
                  'Welcome to Your Progress Dashboard!',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
          Text(
            'Track your sustainability journey and see your impact. Pull down to refresh your data.',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeRow() {
    // Example badge logic (replace with real logic as needed)
    final badges = [
      {
        'label': 'First Goal',
        'icon': Icons.flag,
        'color': AppColors.success,
        'earned': false,
      },
      {
        'label': '10 Challenges',
        'icon': Icons.emoji_events,
        'color': AppColors.secondary,
        'earned': totalChallengesCompleted >= 10,
      },
      {
        'label': '100kg CO₂ Saved',
        'icon': Icons.cloud_done,
        'color': AppColors.info,
        'earned': averageCarbonFootprint < 100 && progress.fold(0.0, (sum, p) => sum + p.carbonFootprint) >= 100,
      },
      {
        'label': 'Energy Saver',
        'icon': Icons.bolt,
        'color': AppColors.warning,
        'earned': averageEnergySavings > 0,
      },
      {
        'label': 'Waste Warrior',
        'icon': Icons.recycling,
        'color': AppColors.success,
        'earned': averageWasteReduction > 0,
      },
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
          child: Text(
            'Achievements',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 15),
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: badges.length,
            separatorBuilder: (_, __) => SizedBox(width: 16),
            itemBuilder: (context, i) {
              final badge = badges[i];
              final bool earned = badge['earned'] == true;
              final Color color = badge['color'] as Color;
              final IconData icon = badge['icon'] as IconData;
              final String label = badge['label'] as String;
              return Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: earned ? color : AppColors.borderLight,
                      boxShadow: earned
                          ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 8, offset: Offset(0, 4))]
                          : [],
                    ),
                    padding: EdgeInsets.all(14),
                    child: Icon(
                      icon,
                      color: earned ? Colors.white : Colors.grey[400],
                      size: 28,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                      color: earned ? AppColors.primaryText : Colors.grey[400],
                      fontWeight: earned ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // Enhanced summary cards with gradients and animated numbers
  Widget _buildSummaryCards() {
    final cardData = [
      {
        'title': 'Carbon Footprint',
        'value': averageCarbonFootprint,
        'unit': 'kg/day',
        'icon': Icons.cloud,
        'gradient': [AppColors.info, AppColors.info.withOpacity(0.7)],
      },
      {
        'title': 'Waste Reduction',
        'value': averageWasteReduction,
        'unit': 'kg',
        'icon': Icons.recycling,
        'gradient': [AppColors.success, AppColors.success.withOpacity(0.7)],
      },
      {
        'title': 'Energy Savings',
        'value': averageEnergySavings,
        'unit': 'kWh',
        'icon': Icons.bolt,
        'gradient': [AppColors.warning, AppColors.warning.withOpacity(0.7)],
      },
      {
        'title': 'Challenges',
        'value': totalChallengesCompleted,
        'unit': 'completed',
        'icon': Icons.emoji_events,
        'gradient': [AppColors.secondary, AppColors.secondary.withOpacity(0.7)],
      },
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: ResponsiveHelper.getAdaptiveSpacing(context),
      mainAxisSpacing: ResponsiveHelper.getAdaptiveSpacing(context),
      childAspectRatio: 1.2,
      children: cardData.map((data) => _buildEnhancedSummaryCard(data)).toList(),
    );
  }

  Widget _buildEnhancedSummaryCard(Map<String, dynamic> data) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: List<Color>.from(data['gradient']),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (data['gradient'] as List<Color>).first.withOpacity(0.18),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      margin: EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                data['icon'],
                color: Colors.white,
                size: ResponsiveHelper.getAdaptiveIconSize(context) * 1.5,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
            Text(
              data['title'],
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 13),
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: (data['value'] is int) ? (data['value'] as int).toDouble() : (data['value'] as double)),
              duration: Duration(milliseconds: 900),
              builder: (context, value, child) {
                return Text(
                  data['value'] is int
                      ? value.toInt().toString() + ' ${data['unit']}'
                      : value.toStringAsFixed(1) + ' ${data['unit']}',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressChart() {
    // Create dynamic chart data from the actual services
    final spotsCarbon = <FlSpot>[];
    final spotsWaste = <FlSpot>[];
    final spotsEnergy = <FlSpot>[];
    
    // Use the generated trend data
    for (int i = 0; i < 7; i++) {
      spotsCarbon.add(FlSpot(i.toDouble(), _carbonTrend.isNotEmpty ? _carbonTrend[i] : 0.0));
      spotsWaste.add(FlSpot(i.toDouble(), _wasteTrend.isNotEmpty ? _wasteTrend[i] : 0.0));
      spotsEnergy.add(FlSpot(i.toDouble(), _energyTrend.isNotEmpty ? _energyTrend[i] : 0.0));
    }
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress Trends (Last 7 Entries)',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            SizedBox(
              height: ResponsiveHelper.getScreenHeight(context) * 0.28,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 36),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: AppColors.borderLight)),
                  minX: 0,
                  maxX: 6, // Fixed at 7 points (0-6)
                  minY: 0,
                  maxY: _calculateMaxY(),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spotsCarbon,
                      isCurved: true,
                      color: AppColors.info,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                    LineChartBarData(
                      spots: spotsWaste,
                      isCurved: true,
                      color: AppColors.success,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                    LineChartBarData(
                      spots: spotsEnergy,
                      isCurved: true,
                      color: AppColors.warning,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.7),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildChartLegend(AppColors.info, 'Carbon'),
                SizedBox(width: 16),
                _buildChartLegend(AppColors.success, 'Waste'),
                SizedBox(width: 16),
                _buildChartLegend(AppColors.warning, 'Energy'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 13),
            color: AppColors.secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentProgress() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            if (progress.isEmpty)
              Text(
                'No recent activity',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  color: AppColors.secondaryText,
                ),
              )
            else
              Column(
                children: progress.take(5).map((p) => _buildTimelineItem(p)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(UserProgress progress) {
    final dateStr = DateFormat('MMM d, yyyy').format(progress.date);
    final items = [
      if (progress.carbonFootprint > 0)
        {
          'icon': Icons.cloud,
          'color': AppColors.info,
          'label': 'Logged Carbon: ${progress.carbonFootprint.toStringAsFixed(1)} kg',
        },
      if (progress.wasteReduction > 0)
        {
          'icon': Icons.recycling,
          'color': AppColors.success,
          'label': 'Waste Reduced: ${progress.wasteReduction.toStringAsFixed(1)} kg',
        },
      if (progress.energySavings > 0)
        {
          'icon': Icons.bolt,
          'color': AppColors.warning,
          'label': 'Energy Saved: ${progress.energySavings.toStringAsFixed(1)} kWh',
        },
      if (progress.challengesCompleted > 0)
        {
          'icon': Icons.emoji_events,
          'color': AppColors.secondary,
          'label': 'Challenges Completed: ${progress.challengesCompleted}',
        },
    ];
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: items.isNotEmpty ? (items[0]['color'] as Color) : AppColors.borderLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    items.isNotEmpty ? (items[0]['icon'] as IconData) : Icons.check,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                if (items.length > 1)
                  Container(
                    width: 4,
                    height: 24.0 * (items.length - 1),
                    color: AppColors.borderLight,
                  ),
              ],
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 13),
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(top: 2.0, bottom: 2.0),
                        child: Row(
                          children: [
                            Icon(item['icon'] as IconData, color: item['color'] as Color, size: 16),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item['label'] as String,
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                                  color: AppColors.primaryText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.7),
      ],
    );
  }

  // Motivational tip widget
  Widget _buildMotivationalTip() {
    final tips = [
      'Small steps make a big difference! 🌱',
      'Every action counts toward a greener planet.',
      'Celebrate your progress, not perfection.',
      'Share your journey and inspire others!',
      'Sustainability is a journey, not a destination.',
      'Keep going—your future self will thank you!',
    ];
    tips.shuffle();
    return Row(
      children: [
        Icon(Icons.lightbulb, color: AppColors.warning, size: 22),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            tips.first,
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              color: AppColors.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
} 