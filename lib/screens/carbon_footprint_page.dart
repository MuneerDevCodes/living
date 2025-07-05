import 'package:flutter/material.dart';
import 'package:living/models/carbon_footprint_model.dart';
import 'package:living/services/carbon_footprint_dao.dart';
import 'package:living/services/auth_helper.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/widgets/alert_error.dart';
import 'package:living/widgets/alert_success.dart';

class CarbonFootprintPage extends StatefulWidget {
  const CarbonFootprintPage({super.key});

  @override
  State<CarbonFootprintPage> createState() => _CarbonFootprintPageState();
}

class _CarbonFootprintPageState extends State<CarbonFootprintPage> {
  List<CarbonFootprintEntry> entries = [];
  bool isLoading = true;
  String? userId;

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
      appBar: AppBar(
        title: const Text('Carbon Footprint Tracker'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Loader()
          : Column(
              children: [
                _buildSummaryCards(),
                Expanded(
                  child: _buildEntriesList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEntryDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Total CO₂',
              '${totalCarbonFootprint.toStringAsFixed(1)} kg',
              Icons.cloud,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'Weekly Avg',
              '${weeklyAverage.toStringAsFixed(1)} kg/day',
              Icons.trending_up,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesList() {
    if (entries.isEmpty) {
      return const Center(
        child: Text(
          'No entries yet. Add your first activity to start tracking!',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green,
              child: Text(
                '${entry.carbonImpact.toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            title: Text(entry.activityType),
            subtitle: Text(
              '${entry.value} ${entry.unit} • ${entry.date.toString().split(' ')[0]}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteEntry(entry),
            ),
          ),
        );
      },
    );
  }

  void _showAddEntryDialog() {
    ActivityType? selectedActivity;
    final valueController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Activity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<ActivityType>(
              decoration: const InputDecoration(labelText: 'Activity Type'),
              value: selectedActivity,
              items: activityTypes.map((activity) {
                return DropdownMenuItem(
                  value: activity,
                  child: Text('${activity.name} (${activity.category})'),
                );
              }).toList(),
              onChanged: (value) => selectedActivity = value,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: valueController,
              decoration: const InputDecoration(labelText: 'Value'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 2,
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
              if (selectedActivity != null && valueController.text.isNotEmpty) {
                final value = double.tryParse(valueController.text);
                if (value != null && userId != null) {
                  final carbonImpact = value * selectedActivity!.carbonFactor;
                  final entry = CarbonFootprintEntry(
                    key: '',
                    userId: userId!,
                    activityType: selectedActivity!.name,
                    value: value,
                    unit: selectedActivity!.unit,
                    carbonImpact: carbonImpact,
                    date: DateTime.now(),
                    notes: notesController.text.isEmpty ? null : notesController.text,
                  );

                  try {
                    await CarbonFootprintDAO.addEntry(entry);
                    Navigator.pop(context);
                    _loadData();
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => const AlertSuccess('Activity added successfully!'),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertError('Failed to add activity: $e'),
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

  void _deleteEntry(CarbonFootprintEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Are you sure you want to delete this ${entry.activityType} entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await CarbonFootprintDAO.deleteEntry(entry.key);
                Navigator.pop(context);
                _loadData();
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => const AlertSuccess('Entry deleted successfully!'),
                  );
                }
              } catch (e) {
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertError('Failed to delete entry: $e'),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
} 