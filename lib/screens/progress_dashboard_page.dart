import 'package:flutter/material.dart';
import 'package:living/models/progress_dashboard_model.dart';
import 'package:living/services/progress_dashboard_dao.dart';
import 'package:living/services/auth_helper.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/widgets/alert_error.dart';
import 'package:living/widgets/alert_success.dart';

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
        appBar: AppBar(
          title: const Text('Progress Dashboard'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Goals'),
            ],
            indicatorColor: Colors.white,
          ),
        ),
        body: isLoading
            ? const Loader()
            : TabBarView(
                children: [
                  _buildOverviewTab(),
                  _buildGoalsTab(),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddGoalDialog,
          backgroundColor: Colors.green,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 24),
          _buildProgressChart(),
          const SizedBox(height: 24),
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
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildSummaryCard(
          'Carbon Footprint',
          '${averageCarbonFootprint.toStringAsFixed(1)} kg/day',
          Icons.cloud,
          Colors.blue,
        ),
        _buildSummaryCard(
          'Waste Reduction',
          '${averageWasteReduction.toStringAsFixed(1)} kg',
          Icons.recycling,
          Colors.green,
        ),
        _buildSummaryCard(
          'Energy Savings',
          '${averageEnergySavings.toStringAsFixed(1)} kWh',
          Icons.bolt,
          Colors.orange,
        ),
        _buildSummaryCard(
          'Challenges',
          '$totalChallengesCompleted completed',
          Icons.emoji_events,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildProgressBars(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBars() {
    if (progress.isEmpty) {
      return const Center(
        child: Text(
          'No progress data available yet.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Get last 6 months of data
    final now = DateTime.now();
    final months = List.generate(6, (index) {
      return DateTime(now.year, now.month - index);
    }).reversed.toList();

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: months.length,
      itemBuilder: (context, index) {
        final month = months[index];
        final monthProgress = progress.where((p) => 
          p.date.year == month.year && p.date.month == month.month
        ).toList();

        double carbonAvg = 0;
        double wasteAvg = 0;
        double energyAvg = 0;

        if (monthProgress.isNotEmpty) {
          carbonAvg = monthProgress.fold(0.0, (sum, p) => sum + p.carbonFootprint) / monthProgress.length;
          wasteAvg = monthProgress.fold(0.0, (sum, p) => sum + p.wasteReduction) / monthProgress.length;
          energyAvg = monthProgress.fold(0.0, (sum, p) => sum + p.energySavings) / monthProgress.length;
        }

        return Container(
          width: 60,
          margin: const EdgeInsets.only(right: 8),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: 20,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.bottomCenter,
                          heightFactor: carbonAvg / 10, // Normalize to 0-1
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Container(
                        width: 20,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.bottomCenter,
                          heightFactor: wasteAvg / 10,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.green[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Container(
                        width: 20,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.bottomCenter,
                          heightFactor: energyAvg / 10,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.orange[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${month.month}/${month.year.toString().substring(2)}',
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentProgress() {
    if (progress.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No recent progress data available.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final recentProgress = progress.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...recentProgress.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Text(
                      '${p.date.day}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${p.date.day}/${p.date.month}/${p.date.year}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'CO₂: ${p.carbonFootprint.toStringAsFixed(1)}kg, Waste: ${p.wasteReduction.toStringAsFixed(1)}kg, Energy: ${p.energySavings.toStringAsFixed(1)}kWh',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${p.totalPoints} pts',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showAddGoalDialog,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Add New Goal', style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
        Expanded(
          child: goals.isEmpty
              ? const Center(
                  child: Text(
                    'No goals set yet. Create your first sustainability goal!',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: goals.length,
                  itemBuilder: (context, index) {
                    final goal = goals[index];
                    final progress = goal.currentValue / goal.targetValue;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal.goalType,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey[300],
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${goal.currentValue.toStringAsFixed(1)} / ${goal.targetValue.toStringAsFixed(1)} ${goal.unit}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(progress * 100).toStringAsFixed(1)}% Complete',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            if (goal.isCompleted)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Completed!',
                                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddGoalDialog() {
    String? selectedGoalType;
    final targetController = TextEditingController();
    final unitController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Progress Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Goal Type'),
              value: selectedGoalType,
              items: [
                'Reduce Carbon Footprint',
                'Increase Waste Reduction',
                'Save Energy',
                'Complete Challenges',
              ].map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) => selectedGoalType = value,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: targetController,
              decoration: const InputDecoration(labelText: 'Target Value'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: unitController,
              decoration: const InputDecoration(labelText: 'Unit'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedGoalType != null && 
                  targetController.text.isNotEmpty &&
                  userId != null) {
                final targetValue = double.tryParse(targetController.text);
                if (targetValue != null) {
                  final goal = ProgressGoal(
                    key: '',
                    userId: userId!,
                    goalType: selectedGoalType!,
                    targetValue: targetValue,
                    currentValue: 0,
                    unit: unitController.text.isEmpty ? 'units' : unitController.text,
                    startDate: DateTime.now(),
                    endDate: DateTime.now().add(const Duration(days: 30)),
                  );

                  try {
                    await ProgressDashboardDAO.addProgressGoal(goal);
                    Navigator.pop(context);
                    _loadData();
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => const AlertSuccess('Goal added successfully!'),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertError('Failed to add goal: $e'),
                      );
                    }
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
} 