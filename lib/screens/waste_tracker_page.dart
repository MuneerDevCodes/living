import 'package:flutter/material.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/models/waste_tracker_model.dart';
import 'package:living/services/waste_tracker_dao.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';

class WasteTrackerPage extends StatefulWidget {
  const WasteTrackerPage({super.key});
  static const String routeName = '/waste-tracker';

  @override
  State<WasteTrackerPage> createState() => _WasteTrackerPageState();
}

class _WasteTrackerPageState extends State<WasteTrackerPage> {
  // final ScrollController _scrollController = ScrollController();
  String? _userId;
  bool _loading = false;
  List<WasteEntry> entries = [];
  List<WasteReductionGoal> goals = [];
  int _selectedTabIndex = 0;

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
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid;
    _loadData();
  }

  Future<void> _loadData() async {
    if (_userId == null) return;
    setState(() => _loading = true);
    try {
      final userEntries = await WasteTrackerDAO.getUserWasteEntries(_userId!);
      final userGoals = await WasteTrackerDAO.getUserGoals(_userId!);
      setState(() {
        entries = userEntries;
        goals = userGoals;
      });
    } catch (e) {
      debugPrint('Error loading waste tracker data: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  double get totalWasteReduced {
    return entries.fold(0.0, (sum, entry) => sum + entry.amount);
  }

  double get recyclingRate {
    if (entries.isEmpty) return 0.0;
    final recyclingEntries = entries.where((e) => 
        e.disposalMethod.toLowerCase() == 'recycling').length;
    return (recyclingEntries / entries.length) * 100;
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
                if (_loading) const Positioned.fill(child: Loader()),
                Column(
                  children: [
                    _buildTabBar(),
                    Expanded(
                      child: _selectedTabIndex == 0 
                          ? _buildEntriesTab() 
                          : _buildGoalsTab(),
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
      padding: ResponsiveHelper.getHorizontalPadding(context),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('Entries', 0),
          ),
          SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
          Expanded(
            child: _buildTabButton('Goals', 1),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: ResponsiveHelper.getVerticalPadding(context),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getAdaptiveBorderRadius(context),
          ),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.white : AppColors.primaryText,
          ),
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
        _buildAddEntryButton(),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Total Waste',
              '${totalWasteReduced.toStringAsFixed(1)} kg',
              Icons.delete,
              AppColors.error,
            ),
          ),
          SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
          Expanded(
            child: _buildSummaryCard(
              'Recycling Rate',
              '${recyclingRate.toStringAsFixed(1)}%',
              Icons.recycling,
              AppColors.success,
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
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
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
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
            Text(
              value,
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesList() {
    if (entries.isEmpty) {
      return Center(
        child: Text(
          'No entries yet. Add your first waste entry to start tracking!',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
            color: AppColors.secondaryText,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          margin: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getDisposalMethodColor(entry.disposalMethod),
              child: Icon(
                _getDisposalMethodIcon(entry.disposalMethod),
                color: AppColors.white,
                size: ResponsiveHelper.getAdaptiveIconSize(context),
              ),
            ),
            title: Text(
              entry.wasteType,
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              '${entry.amount} ${entry.unit} • ${entry.disposalMethod} • ${entry.date.toString().split(' ')[0]}',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                color: AppColors.secondaryText,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.delete, 
                color: AppColors.error,
                size: ResponsiveHelper.getAdaptiveIconSize(context),
              ),
              onPressed: () => _deleteEntry(entry),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddEntryButton() {
    return Container(
      padding: ResponsiveHelper.getHorizontalPadding(context),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _showAddEntryDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            padding: ResponsiveHelper.getVerticalPadding(context),
          ),
          child: Text(
            'Add New Entry',
            style: TextStyle(
              color: AppColors.white,
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalsTab() {
    return Column(
      children: [
        Container(
          padding: ResponsiveHelper.getHorizontalPadding(context),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showAddGoalDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: ResponsiveHelper.getVerticalPadding(context),
              ),
              child: Text(
                'Add New Goal',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: goals.isEmpty
              ? Center(
                  child: Text(
                    'No goals set yet. Create your first waste reduction goal!',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                      color: AppColors.secondaryText,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: ResponsiveHelper.getAdaptivePadding(context),
                  itemCount: goals.length,
                  itemBuilder: (context, index) {
                    final goal = goals[index];
                    final progress = goal.currentAmount / goal.targetAmount;
                    return Card(
                      margin: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context)),
                      child: Padding(
                        padding: ResponsiveHelper.getAdaptivePadding(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal.goalType,
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: AppColors.borderLight,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                            ),
                            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                            Text(
                              '${goal.currentAmount.toStringAsFixed(1)} / ${goal.targetAmount.toStringAsFixed(1)} ${goal.unit}',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                            Text(
                              '${(progress * 100).toStringAsFixed(1)}% Complete',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                                color: AppColors.secondaryText,
                              ),
                            ),
                            if (goal.isCompleted)
                              Container(
                                margin: EdgeInsets.only(top: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                                padding: EdgeInsets.symmetric(
                                  horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4,
                                  vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(
                                    ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.6,
                                  ),
                                ),
                                child: Text(
                                  'Completed!',
                                  style: TextStyle(
                                    color: AppColors.success, 
                                    fontWeight: FontWeight.bold,
                                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                                  ),
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
        return AppColors.success;
      case 'composting':
        return AppColors.warning;
      case 'landfill':
        return AppColors.error;
      case 'donation':
        return AppColors.info;
      case 'reuse':
        return AppColors.warning;
      default:
        return AppColors.mutedText;
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

    final wasteTypes = ['Plastic', 'Paper', 'Glass', 'Metal', 'Organic', 'Electronic', 'Other'];
    final disposalMethods = ['Recycling', 'Composting', 'Landfill', 'Donation', 'Reuse'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add Waste Entry',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Waste Type',
                labelStyle: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                ),
              ),
              value: selectedWasteType,
              items: wasteTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) => selectedWasteType = value,
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Disposal Method',
                labelStyle: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                ),
              ),
              value: selectedDisposalMethod,
              items: disposalMethods.map((method) {
                return DropdownMenuItem(value: method, child: Text(method));
              }).toList(),
              onChanged: (value) => selectedDisposalMethod = value,
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Amount (kg)',
                labelStyle: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                labelStyle: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                ),
              ),
              maxLines: 2,
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
            onPressed: () async {
              if (selectedWasteType != null && 
                  selectedDisposalMethod != null && 
                  amountController.text.isNotEmpty &&
                  _userId != null) {
                final amount = double.tryParse(amountController.text);
                if (amount != null) {
                  final entry = WasteEntry(
                    key: '',
                    userId: _userId!,
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Waste entry added successfully!',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                            ),
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to add waste entry: $e',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                            ),
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                }
              }
            },
            child: Text(
              'Add',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddGoalDialog() {
    String? selectedGoalType;
    final targetController = TextEditingController();
    final unitController = TextEditingController(text: 'kg');

    final wasteTypes = ['Plastic', 'Paper', 'Glass', 'Metal', 'Organic', 'Electronic', 'Other'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add Waste Reduction Goal',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Goal Type',
                labelStyle: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                ),
              ),
              value: selectedGoalType,
              items: wasteTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text('Reduce $type'));
              }).toList(),
              onChanged: (value) => selectedGoalType = value,
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            TextField(
              controller: targetController,
              decoration: InputDecoration(
                labelText: 'Target Amount',
                labelStyle: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            TextField(
              controller: unitController,
              decoration: InputDecoration(
                labelText: 'Unit',
                labelStyle: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                ),
              ),
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
            onPressed: () async {
              if (selectedGoalType != null && 
                  targetController.text.isNotEmpty &&
                  _userId != null) {
                final targetAmount = double.tryParse(targetController.text);
                if (targetAmount != null) {
                  final goal = WasteReductionGoal(
                    key: '',
                    userId: _userId!,
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
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to add goal: $e',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                            ),
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                }
              }
            },
            child: Text(
              'Add',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteEntry(WasteEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Entry',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this ${entry.wasteType} entry?',
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
            onPressed: () async {
              try {
                await WasteTrackerDAO.deleteWasteEntry(entry.key);
                Navigator.pop(context);
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Entry deleted successfully!',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        ),
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to delete entry: $e',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        ),
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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