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

class CarbonFootprintPage extends StatefulWidget {
  const CarbonFootprintPage({super.key});

  @override
  State<CarbonFootprintPage> createState() => _CarbonFootprintPageState();
}

class _CarbonFootprintPageState extends State<CarbonFootprintPage> {
  List<CarbonFootprintEntry> entries = [];
  bool isLoading = true;
  String? userId;
  
  // Carbon footprint variables
  double get currentFootprint => weeklyAverage;
  double get targetFootprint => 5.0; // Target of 5 kg CO2/day

  final List<ActivityType> activityTypes = [
    ActivityType(name: 'Car Travel', category: 'Transportation', carbonFactor: 0.404, unit: 'km'),
    ActivityType(name: 'Bus Travel', category: 'Transportation', carbonFactor: 0.105, unit: 'km'),
    ActivityType(name: 'Train Travel', category: 'Transportation', carbonFactor: 0.041, unit: 'km'),
    ActivityType(name: 'Electricity Usage', category: 'Energy', carbonFactor: 0.92, unit: 'kWh'),
    ActivityType(name: 'Natural Gas', category: 'Energy', carbonFactor: 2.02, unit: 'm³'),
    ActivityType(name: 'Meat Consumption', category: 'Food', carbonFactor: 2.5, unit: 'kg'),
    ActivityType(name: 'Dairy Consumption', category: 'Food', carbonFactor: 1.4, unit: 'kg'),
    ActivityType(name: 'Vegetables', category: 'Food', carbonFactor: 0.2, unit: 'kg'),
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
        entries = await CarbonFootprintDAO.getUserEntries(userId!);
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

  double get totalCarbonFootprint {
    return entries.fold(0.0, (sum, entry) => sum + entry.carbonImpact);
  }

  double get weeklyAverage {
    if (entries.isEmpty) return 0.0;
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weeklyEntries = entries.where((entry) => entry.date.isAfter(weekAgo)).toList();
    if (weeklyEntries.isEmpty) return 0.0;
    return weeklyEntries.fold(0.0, (sum, entry) => sum + entry.carbonImpact) / 7;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Header.buildDrawer(context),
      body: Column(
        children: [
          const Header(),
          Expanded(
            child: Stack(
              children: [
                if (isLoading) const Positioned.fill(child: Loader()),
                SingleChildScrollView(
                  padding: ResponsiveHelper.getAdaptivePadding(context),
                  child: Column(
                    children: [
                      _buildOverviewCard(),
                      SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                      _buildBreakdownCard(),
                      SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                      _buildTipsCard(),
                      SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                      _buildActionsCard(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Footer(),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    final progress = (targetFootprint / currentFootprint).clamp(0.0, 1.0);
    final color = currentFootprint <= targetFootprint ? AppColors.success : AppColors.warning;

    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          children: [
            Text(
              'Your Carbon Footprint',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 20),
                fontWeight: FontWeight.bold,
              ),
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
                        'Target: ${targetFootprint.toStringAsFixed(1)}',
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

  Widget _buildBreakdownCard() {
    final categories = [
      {'name': 'Transportation', 'value': 4.2, 'color': AppColors.error},
      {'name': 'Energy', 'value': 3.8, 'color': AppColors.warning},
      {'name': 'Food', 'value': 2.5, 'color': AppColors.success},
      {'name': 'Waste', 'value': 1.2, 'color': AppColors.info},
      {'name': 'Other', 'value': 0.8, 'color': AppColors.mutedText},
    ];

    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Breakdown by Category',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            ...categories.map((category) => Padding(
              padding: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
              child: Row(
                children: [
                  Container(
                    width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8,
                    height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8,
                    decoration: BoxDecoration(
                      color: category['color'] as Color,
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.4,
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                  Expanded(
                    child: Text(
                      category['name'] as String,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '${(category['value'] as double).toStringAsFixed(1)} kg',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      fontWeight: FontWeight.bold,
                      color: category['color'] as Color,
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

  Widget _buildTipsCard() {
    final tips = [
      'Use public transportation or carpool',
      'Switch to energy-efficient appliances',
      'Reduce meat consumption',
      'Recycle and compost waste',
      'Use renewable energy sources',
    ];

    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tips to Reduce Your Footprint',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
              ),
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

  Widget _buildActionsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _logActivity,
                    icon: Icon(
                      Icons.add,
                      size: ResponsiveHelper.getAdaptiveIconSize(context),
                    ),
                    label: Text(
                      'Log Activity',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.white,
                      padding: ResponsiveHelper.getAdaptivePadding(context),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _setGoal,
                    icon: Icon(
                      Icons.flag,
                      size: ResponsiveHelper.getAdaptiveIconSize(context),
                    ),
                    label: Text(
                      'Set Goal',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      foregroundColor: AppColors.white,
                      padding: ResponsiveHelper.getAdaptivePadding(context),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _viewHistory,
                icon: Icon(
                  Icons.history,
                  size: ResponsiveHelper.getAdaptiveIconSize(context),
                ),
                label: Text(
                  'View History',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.white,
                  padding: ResponsiveHelper.getAdaptivePadding(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logActivity() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Log Carbon Activity',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'What activity did you do today?',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            // Add form fields here
          ],
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
                    'Activity logged successfully!',
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
              'Log',
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

  void _setGoal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Set Carbon Goal',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Set your target carbon footprint goal.',
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
                    'Goal set successfully!',
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
              'Set Goal',
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

  void _viewHistory() {
    Navigator.pushNamed(context, '/progress-dashboard');
  }
} 