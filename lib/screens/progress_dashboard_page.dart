import 'package:flutter/material.dart';
import 'package:living/models/progress_dashboard_model.dart';
import 'package:living/services/progress_dashboard_dao.dart';
import 'package:living/services/auth_helper.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/widgets/alert_error.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';

class ProgressDashboardPage extends StatefulWidget {
  const ProgressDashboardPage({super.key});

  @override
  State<ProgressDashboardPage> createState() => _ProgressDashboardPageState();
}

class _ProgressDashboardPageState extends State<ProgressDashboardPage> {
  List<UserProgress> progress = [];
  List<ProgressGoal> goals = [];
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
        progress = await ProgressDashboardDAO.getUserProgress(userId!);
        goals = await ProgressDashboardDAO.getUserGoals(userId!);
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertError('Failed to load progress data: $e'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  double get averageCarbonFootprint {
    if (progress.isEmpty) return 0.0;
    return progress.fold(0.0, (sum, p) => sum + p.carbonFootprint) / progress.length;
  }

  double get averageWasteReduction {
    if (progress.isEmpty) return 0.0;
    return progress.fold(0.0, (sum, p) => sum + p.wasteReduction) / progress.length;
  }

  double get averageEnergySavings {
    if (progress.isEmpty) return 0.0;
    return progress.fold(0.0, (sum, p) => sum + p.energySavings) / progress.length;
  }

  int get totalChallengesCompleted {
    if (progress.isEmpty) return 0;
    return progress.fold(0, (sum, p) => sum + p.challengesCompleted);
  }

  int get totalPoints {
    if (progress.isEmpty) return 0;
    return progress.fold(0, (sum, p) => sum + p.totalPoints);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
                                'Overview',
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                            Tab(
                              child: Text(
                                'Goals',
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
                            _buildOverviewTab(),
                            _buildGoalsTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Footer(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddGoalDialog,
          backgroundColor: AppColors.success,
          child: Icon(
            Icons.add,
            color: AppColors.white,
            size: ResponsiveHelper.getAdaptiveIconSize(context),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      child: Column(
        children: [
          _buildSummaryCards(),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          _buildProgressChart(),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          _buildRecentProgress(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: ResponsiveHelper.getAdaptiveSpacing(context),
      mainAxisSpacing: ResponsiveHelper.getAdaptiveSpacing(context),
      childAspectRatio: 1.2,
      children: [
        _buildSummaryCard(
          'Carbon Footprint',
          '${averageCarbonFootprint.toStringAsFixed(1)} kg/day',
          Icons.cloud,
          AppColors.info,
        ),
        _buildSummaryCard(
          'Waste Reduction',
          '${averageWasteReduction.toStringAsFixed(1)} kg',
          Icons.recycling,
          AppColors.success,
        ),
        _buildSummaryCard(
          'Energy Savings',
          '${averageEnergySavings.toStringAsFixed(1)} kWh',
          Icons.bolt,
          AppColors.warning,
        ),
        _buildSummaryCard(
          'Challenges',
          '$totalChallengesCompleted completed',
          Icons.emoji_events,
          AppColors.secondary,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: ResponsiveHelper.getAdaptiveIconSize(context) * 2,
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
            Text(
              title,
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
            Text(
              value,
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressChart() {
    return Card(
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Progress',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            SizedBox(
              height: ResponsiveHelper.getScreenHeight(context) * 0.3,
              child: _buildChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    // Simple chart implementation
    return Container(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      child: Column(
        children: [
          _buildChartBar('Carbon Footprint', averageCarbonFootprint / 10, AppColors.info),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
          _buildChartBar('Waste Reduction', averageWasteReduction / 5, AppColors.success),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
          _buildChartBar('Energy Savings', averageEnergySavings / 20, AppColors.warning),
        ],
      ),
    );
  }

  Widget _buildChartBar(String label, double value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: ResponsiveHelper.getScreenWidth(context) * 0.3,
          child: Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
              color: AppColors.secondaryText,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8,
            margin: EdgeInsets.only(left: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentProgress() {
    return Card(
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
              ...progress.take(5).map((p) => _buildProgressItem(p)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(UserProgress progress) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
      child: Row(
        children: [
          Container(
            width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8,
            height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8,
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.4,
              ),
            ),
            child: Icon(
              Icons.check,
              color: AppColors.white,
              size: ResponsiveHelper.getAdaptiveIconSize(context) * 0.8,
            ),
          ),
          SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progress Update',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Carbon: ${progress.carbonFootprint.toStringAsFixed(1)} kg',
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
    );
  }

  Widget _buildGoalsTab() {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      child: Column(
        children: [
          _buildGoalsList(),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          _buildAddGoalButton(),
        ],
      ),
    );
  }

  Widget _buildGoalsList() {
    if (goals.isEmpty) {
      return Card(
        child: Padding(
          padding: ResponsiveHelper.getAdaptivePadding(context),
          child: Column(
            children: [
              Icon(
                Icons.flag,
                size: ResponsiveHelper.getAdaptiveIconSize(context) * 3,
                color: AppColors.mutedText,
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Text(
                'No goals set yet',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
              Text(
                'Set your first sustainability goal to start tracking your progress',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: goals.map((goal) => _buildGoalCard(goal)).toList(),
    );
  }

  Widget _buildGoalCard(ProgressGoal goal) {
    final progress = goal.currentValue / goal.targetValue;
    final color = progress >= 1.0 ? AppColors.success : AppColors.primary;

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
                  child: Text(
                    goal.goalType,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _deleteGoal(goal.key),
                  icon: Icon(
                    Icons.delete,
                    color: AppColors.error,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
            Text(
              'Target: ${goal.targetValue} ${goal.unit}',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                color: AppColors.secondaryText,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
            Text(
              '${goal.currentValue.toStringAsFixed(1)} / ${goal.targetValue.toStringAsFixed(1)}',
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

  Widget _buildAddGoalButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _showAddGoalDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          padding: ResponsiveHelper.getAdaptivePadding(context),
        ),
        child: Text(
          'Add New Goal',
          style: TextStyle(
            color: AppColors.white,
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
          ),
        ),
      ),
    );
  }

  void _showAddGoalDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final targetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add New Goal',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Goal Title',
                labelStyle: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                ),
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                ),
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            TextField(
              controller: targetController,
              decoration: InputDecoration(
                labelText: 'Target Value',
                labelStyle: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
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
              // Add goal logic here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Goal added successfully!',
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
              'Add Goal',
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

  void _deleteGoal(String goalId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Goal',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this goal?',
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
              // Delete goal logic here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Goal deleted successfully!',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(
              'Delete',
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