import 'package:flutter/material.dart';
import 'package:living/models/waste_tracker_model.dart';
import 'package:living/services/waste_tracker_dao.dart';
import 'package:living/services/auth_helper.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/widgets/alert_error.dart';
import 'package:living/widgets/alert_success.dart';

class WasteTrackerPage extends StatefulWidget {
  const WasteTrackerPage({super.key});

  @override
  State<WasteTrackerPage> createState() => _WasteTrackerPageState();
}

class _WasteTrackerPageState extends State<WasteTrackerPage> {
  List<WasteEntry> entries = [];
  List<WasteReductionGoal> goals = [];
  bool isLoading = true;
  String? userId;

  final List<String> wasteTypes = [
    'Plastic',
    'Paper',
    'Glass',
    'Metal',
    'Organic',
    'Electronic',
    'Textile',
  ];

  final List<String> disposalMethods = [
    'Recycling',
    'Composting',
    'Landfill',
    'Donation',
    'Reuse',
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
        entries = await WasteTrackerDAO.getUserWasteEntries(userId!);
        goals = await WasteTrackerDAO.getUserGoals(userId!);
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

  double get totalWasteReduced {
    return entries.fold(0.0, (sum, entry) => sum + entry.amount);
  }

  double get recyclingRate {
    if (entries.isEmpty) return 0.0;
    final recycledEntries = entries.where((entry) => 
      entry.disposalMethod == 'Recycling' || 
      entry.disposalMethod == 'Composting' ||
      entry.disposalMethod == 'Donation'
    ).toList();
    return (recycledEntries.fold(0.0, (sum, entry) => sum + entry.amount) / totalWasteReduced) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Waste Tracker'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Entries'),
              Tab(text: 'Goals'),
            ],
            indicatorColor: Colors.white,
          ),
        ),
        body: isLoading
            ? const Loader()
            : TabBarView(
                children: [
                  _buildEntriesTab(),
                  _buildGoalsTab(),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddEntryDialog,
          backgroundColor: Colors.green,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEntriesTab() {
    return Column(
      children: [
        _buildSummaryCards(),
        Expanded(
          child: _buildEntriesList(),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Total Waste',
              '${totalWasteReduced.toStringAsFixed(1)} kg',
              Icons.delete,
              Colors.red,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'Recycling Rate',
              '${recyclingRate.toStringAsFixed(1)}%',
              Icons.recycling,
              Colors.green,
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
          'No entries yet. Add your first waste entry to start tracking!',
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
              backgroundColor: _getDisposalMethodColor(entry.disposalMethod),
              child: Icon(
                _getDisposalMethodIcon(entry.disposalMethod),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(entry.wasteType),
            subtitle: Text(
              '${entry.amount} ${entry.unit} • ${entry.disposalMethod} • ${entry.date.toString().split(' ')[0]}',
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
                    'No goals set yet. Create your first waste reduction goal!',
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

  Color _getDisposalMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'recycling':
        return Colors.green;
      case 'composting':
        return Colors.brown;
      case 'landfill':
        return Colors.red;
      case 'donation':
        return Colors.blue;
      case 'reuse':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getDisposalMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'recycling':
        return Icons.recycling;
      case 'composting':
        return Icons.eco;
      case 'landfill':
        return Icons.delete;
      case 'donation':
        return Icons.favorite;
      case 'reuse':
        return Icons.refresh;
      default:
        return Icons.delete;
    }
  }

  void _showAddEntryDialog() {
    String? selectedWasteType;
    String? selectedDisposalMethod;
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Waste Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Waste Type'),
              value: selectedWasteType,
              items: wasteTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) => selectedWasteType = value,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Disposal Method'),
              value: selectedDisposalMethod,
              items: disposalMethods.map((method) {
                return DropdownMenuItem(value: method, child: Text(method));
              }).toList(),
              onChanged: (value) => selectedDisposalMethod = value,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount (kg)'),
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
              if (selectedWasteType != null && 
                  selectedDisposalMethod != null && 
                  amountController.text.isNotEmpty &&
                  userId != null) {
                final amount = double.tryParse(amountController.text);
                if (amount != null) {
                  final entry = WasteEntry(
                    key: '',
                    userId: userId!,
                    wasteType: selectedWasteType!,
                    amount: amount,
                    unit: 'kg',
                    disposalMethod: selectedDisposalMethod!,
                    date: DateTime.now(),
                    notes: notesController.text.isEmpty ? null : notesController.text,
                  );

                  try {
                    await WasteTrackerDAO.addWasteEntry(entry);
                    Navigator.pop(context);
                    _loadData();
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => const AlertSuccess('Waste entry added successfully!'),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertError('Failed to add waste entry: $e'),
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

  void _showAddGoalDialog() {
    String? selectedGoalType;
    final targetController = TextEditingController();
    final unitController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Waste Reduction Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Goal Type'),
              value: selectedGoalType,
              items: wasteTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text('Reduce $type'));
              }).toList(),
              onChanged: (value) => selectedGoalType = value,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: targetController,
              decoration: const InputDecoration(labelText: 'Target Amount'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: unitController,
              decoration: const InputDecoration(labelText: 'Unit'),
              initialValue: 'kg',
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
                final targetAmount = double.tryParse(targetController.text);
                if (targetAmount != null) {
                  final goal = WasteReductionGoal(
                    key: '',
                    userId: userId!,
                    goalType: selectedGoalType!,
                    targetAmount: targetAmount,
                    unit: unitController.text.isEmpty ? 'kg' : unitController.text,
                    startDate: DateTime.now(),
                    endDate: DateTime.now().add(const Duration(days: 30)),
                  );

                  try {
                    await WasteTrackerDAO.addWasteGoal(goal);
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

  void _deleteEntry(WasteEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Are you sure you want to delete this ${entry.wasteType} entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await WasteTrackerDAO.deleteWasteEntry(entry.key);
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