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
  String? _userId;
  bool _loading = false;
  List<WasteEntry> entries = [];
  List<WasteReductionGoal> goals = [];
  int _selectedTabIndex = 0;
  bool _showOnboarding = false;

  // Enhanced waste types with descriptions and environmental impact
  final List<Map<String, dynamic>> wasteTypes = [
    {
      'name': 'Plastic',
      'description': 'Plastic bottles, bags, containers, packaging',
      'impact': 'Takes 450+ years to decompose, harms marine life',
      'icon': Icons.local_drink,
      'color': Colors.blue,
      'tips': ['Rinse before recycling', 'Check local recycling rules', 'Reduce single-use plastics']
    },
    {
      'name': 'Paper',
      'description': 'Newspapers, magazines, cardboard, office paper',
      'impact': 'Recyclable, saves trees and energy',
      'icon': Icons.description,
      'color': Colors.brown,
      'tips': ['Keep dry and clean', 'Remove plastic windows', 'Flatten cardboard boxes']
    },
    {
      'name': 'Glass',
      'description': 'Bottles, jars, containers',
      'impact': '100% recyclable, saves energy and resources',
      'icon': Icons.wine_bar,
      'color': Colors.green,
      'tips': ['Rinse thoroughly', 'Remove caps and lids', 'Don\'t break glass']
    },
    {
      'name': 'Metal',
      'description': 'Aluminum cans, steel containers, scrap metal',
      'impact': 'Highly recyclable, saves 95% energy vs new production',
      'icon': Icons.restaurant,
      'color': Colors.grey,
      'tips': ['Rinse cans clean', 'Crush to save space', 'Separate aluminum and steel']
    },
    {
      'name': 'Organic',
      'description': 'Food waste, yard waste, compostable materials',
      'impact': 'Creates nutrient-rich compost, reduces methane',
      'icon': Icons.eco,
      'color': Colors.green,
      'tips': ['Avoid meat and dairy', 'Chop large items', 'Keep moist but not wet']
    },
    {
      'name': 'Electronic',
      'description': 'Batteries, electronics, appliances',
      'impact': 'Contains toxic materials, requires special handling',
      'icon': Icons.devices,
      'color': Colors.orange,
      'tips': ['Find e-waste drop-off', 'Remove batteries', 'Don\'t throw in regular trash']
    },
    {
      'name': 'Textile',
      'description': 'Clothing, fabric, shoes, accessories',
      'impact': 'Textile waste fills landfills, takes 200+ years to decompose',
      'icon': Icons.checkroom,
      'color': Colors.purple,
      'tips': ['Donate if usable', 'Find textile recycling', 'Repair before replacing']
    },
  ];

  final List<Map<String, dynamic>> disposalMethods = [
    {
      'name': 'Recycling',
      'description': 'Process materials into new products',
      'impact': 'Reduces landfill waste, saves energy and resources',
      'icon': Icons.recycling,
      'color': AppColors.success,
      'score': 5
    },
    {
      'name': 'Composting',
      'description': 'Natural decomposition of organic materials',
      'impact': 'Creates nutrient-rich soil, reduces methane emissions',
      'icon': Icons.eco,
      'color': AppColors.warning,
      'score': 4
    },
    {
      'name': 'Donation',
      'description': 'Give usable items to others in need',
      'impact': 'Extends product life, helps community, reduces waste',
      'icon': Icons.favorite,
      'color': AppColors.info,
      'score': 5
    },
    {
      'name': 'Reuse',
      'description': 'Use items again for same or different purpose',
      'impact': 'Prevents waste generation, saves money and resources',
      'icon': Icons.refresh,
      'color': AppColors.warning,
      'score': 5
    },
    {
      'name': 'Landfill',
      'description': 'Disposal in waste management facility',
      'impact': 'Least sustainable option, contributes to pollution',
      'icon': Icons.delete,
      'color': AppColors.error,
      'score': 1
    },
  ];

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid;
    _loadData();
    _checkFirstTimeUser();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _checkFirstTimeUser() async {
    // Check if user has any entries
    if (_userId != null) {
      final userEntries = await WasteTrackerDAO.getUserWasteEntries(_userId!);
      if (userEntries.isEmpty) {
        setState(() {
          _showOnboarding = true;
        });
      }
    }
  }

  Future<void> _loadData() async {
    if (_userId == null) return;
    setState(() => _loading = true);
    try {
      final userEntries = await WasteTrackerDAO.getUserWasteEntries(_userId!);
      final userGoals = await WasteTrackerDAO.getUserGoals(_userId!);
      // Auto-update each goal's currentAmount based on entries
      for (final goal in userGoals) {
        final relevantEntries = userEntries.where((e) => e.wasteType == goal.goalType).toList();
        final sum = relevantEntries.fold(0.0, (s, e) => s + e.amount);
        if ((sum != goal.currentAmount) || (goal.isCompleted != (sum >= goal.targetAmount))) {
          final updatedGoal = WasteReductionGoal(
            key: goal.key,
            userId: goal.userId,
            goalType: goal.goalType,
            targetAmount: goal.targetAmount,
            unit: goal.unit,
            startDate: goal.startDate,
            endDate: goal.endDate,
            currentAmount: sum,
            isCompleted: sum >= goal.targetAmount,
          );
          await WasteTrackerDAO.updateWasteGoal(updatedGoal);
        }
      }
      // Reload updated goals
      final refreshedGoals = await WasteTrackerDAO.getUserGoals(_userId!);
      setState(() {
        entries = userEntries;
        goals = refreshedGoals;
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

  double get environmentalScore {
    if (entries.isEmpty) return 0.0;
    double totalScore = 0.0;
    for (var entry in entries) {
      final method = disposalMethods.firstWhere(
        (m) => m['name'].toLowerCase() == entry.disposalMethod.toLowerCase(),
        orElse: () => {'score': 1}
      );
      totalScore += method['score'] * entry.amount;
    }
    return (totalScore / totalWasteReduced) * 20; // Scale to 0-100
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Header.buildDrawer(context),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Move FAB higher up above nav bar
        child: FloatingActionButton.extended(
          onPressed: _selectedTabIndex == 0 ? _showAddEntryDialog : _showAddGoalDialog,
          backgroundColor: AppColors.success,
          foregroundColor: AppColors.white,
          icon: Icon(_selectedTabIndex == 0 ? Icons.add : Icons.flag),
          label: Text(_selectedTabIndex == 0 ? 'Add Entry' : 'Add Goal'),
          elevation: 4,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Column(
        children: [
          const Header(),
          Expanded(
            child: Stack(
              children: [
                  if (_loading) 
                    const Positioned.fill(
                      child: Center(child: Loader()),
                    ),
                  if (!_loading)
                Column(
                  children: [
                        _buildWelcomeSection(),
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
            const Footer(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: ResponsiveHelper.getHorizontalPadding(context),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: ResponsiveHelper.getAdaptivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.eco,
                    color: AppColors.success,
                    size: ResponsiveHelper.getAdaptiveIconSize(context) * 1.5,
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                  Expanded(
                    child: Text(
                      'Waste Reduction Tracker',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getTitleFontSize(context),
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                  if (_showOnboarding)
                    IconButton(
                      icon: Icon(Icons.help_outline, color: AppColors.info),
                      onPressed: _showOnboardingDialog,
                      tooltip: 'Get started guide',
                    ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
              Text(
                'Track your waste reduction journey and make a positive environmental impact. Every entry helps you understand your consumption patterns and find ways to reduce waste.',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getBodyFontSize(context),
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: ResponsiveHelper.getHorizontalPadding(context),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('Track Entries', 0, Icons.list_alt),
          ),
          SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
          Expanded(
            child: _buildTabButton('Set Goals', 1, Icons.flag),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () {
        if (mounted) {
          setState(() => _selectedTabIndex = index);
        }
      },
      borderRadius: BorderRadius.circular(
        ResponsiveHelper.getAdaptiveBorderRadius(context),
      ),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.white : AppColors.primaryText,
              size: ResponsiveHelper.getAdaptiveIconSize(context),
            ),
            SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.white : AppColors.primaryText,
          ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSummaryCards(),
          _buildEntriesList(),
        // _buildAddEntryButton(), // Removed as per user request
      ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      child: Column(
        children: [
          Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Total Waste',
              '${totalWasteReduced.toStringAsFixed(1)} kg',
              Icons.delete,
              AppColors.error,
                  'Total waste tracked',
            ),
          ),
          SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
          Expanded(
            child: _buildSummaryCard(
              'Recycling Rate',
              '${recyclingRate.toStringAsFixed(1)}%',
              Icons.recycling,
              AppColors.success,
                  'Percentage recycled',
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Environmental Score',
                  '${environmentalScore.toStringAsFixed(0)}/100',
                  Icons.eco,
                  AppColors.info,
                  'Based on disposal methods',
                ),
              ),
              SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
              Expanded(
                child: _buildSummaryCard(
                  'Entries',
                  '${entries.length}',
                  Icons.assessment,
                  AppColors.primary,
                  'Total entries logged',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          children: [
            Icon(
              icon, 
              color: color, 
                size: ResponsiveHelper.getAdaptiveIconSize(context) * 1.5,
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
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
              ),
                textAlign: TextAlign.center,
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntriesList() {
    if (entries.isEmpty) {
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.4,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: ResponsiveHelper.getAdaptiveIconSize(context) * 2.5,
                  color: AppColors.mutedText,
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8),
                Text(
                  'No entries yet',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getSubtitleFontSize(context),
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                Padding(
                  padding: ResponsiveHelper.getHorizontalPadding(context),
        child: Text(
                    'Start tracking your waste reduction journey!\nTap the + button below to add your first entry.',
                    textAlign: TextAlign.center,
          style: TextStyle(
                      fontSize: ResponsiveHelper.getBodyFontSize(context),
            color: AppColors.secondaryText,
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8),
                Container(
                  padding: ResponsiveHelper.getAdaptivePadding(context),
                  margin: ResponsiveHelper.getHorizontalPadding(context),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: AppColors.info, size: 20),
                          SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                          Text(
                            'Quick Tips',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                              fontWeight: FontWeight.bold,
                              color: AppColors.info,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                      Text(
                        '• Use a kitchen scale for accurate measurements\n• Start with common items like plastic bottles and paper\n• Choose the most sustainable disposal method available\n• Add notes to track patterns and improvements',
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
          ),
        ),
      );
    }

    return Column(
      children: entries.map((entry) {
        return Card(
          margin: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
          child: ExpansionTile(
            key: ValueKey('entry_${entry.key}'),
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
              '${entry.amount} ${entry.unit} • ${entry.disposalMethod} • ${_formatDate(entry.date)}',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                color: AppColors.secondaryText,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: AppColors.info,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                  ),
                  onPressed: () => _editEntry(entry),
                  tooltip: 'Edit entry',
                ),
                IconButton(
              icon: Icon(
                Icons.delete, 
                color: AppColors.error,
                size: ResponsiveHelper.getAdaptiveIconSize(context),
              ),
              onPressed: () => _deleteEntry(entry),
                  tooltip: 'Delete entry',
                ),
              ],
            ),
            children: [
              Padding(
                padding: ResponsiveHelper.getAdaptivePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                      Text(
                        'Notes:',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                      Text(
                        entry.notes!,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                          color: AppColors.secondaryText,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                    ],
                    _buildEnvironmentalImpact(entry),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEnvironmentalImpact(WasteEntry entry) {
    final wasteType = wasteTypes.firstWhere(
      (type) => type['name'] == entry.wasteType,
      orElse: () => {'impact': 'Environmental impact varies by type'}
    );
    
    final disposalMethod = disposalMethods.firstWhere(
      (method) => method['name'] == entry.disposalMethod,
      orElse: () => {'impact': 'Impact depends on disposal method'}
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Environmental Impact:',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
        Text(
          '• ${wasteType['impact']}',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
            color: AppColors.secondaryText,
          ),
        ),
        Text(
          '• ${disposalMethod['impact']}',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalsTab() {
    return Column(
      children: [
        Expanded(
          child: goals.isEmpty
              ? SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            size: ResponsiveHelper.getAdaptiveIconSize(context) * 2.5,
                            color: AppColors.mutedText,
                          ),
                          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8),
                          Text(
                            'No goals set yet',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getSubtitleFontSize(context),
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                            ),
                          ),
                          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                          Padding(
                            padding: ResponsiveHelper.getHorizontalPadding(context),
                  child: Text(
                              'Set waste reduction goals to track your progress\nand stay motivated on your sustainability journey!',
                              textAlign: TextAlign.center,
                    style: TextStyle(
                                fontSize: ResponsiveHelper.getBodyFontSize(context),
                      color: AppColors.secondaryText,
                              ),
                            ),
                          ),
                          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8),
                          Container(
                            padding: ResponsiveHelper.getAdaptivePadding(context),
                            margin: ResponsiveHelper.getHorizontalPadding(context),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.tips_and_updates, color: AppColors.success, size: 20),
                                    SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                                    Text(
                                      'Goal Setting Tips',
                                      style: TextStyle(
                                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                                Text(
                                  '• Start with realistic, achievable targets\n• Focus on one waste type at a time\n• Set time-bound goals (7, 30, or 90 days)\n• Track progress regularly to stay motivated',
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
                            Row(
                              children: [
                                Icon(
                                  Icons.flag,
                                  color: AppColors.primary,
                                  size: ResponsiveHelper.getAdaptiveIconSize(context),
                                ),
                                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                                Expanded(
                                  child: Text(
                              goal.goalType,
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                                fontWeight: FontWeight.bold,
                              ),
                                  ),
                                ),
                                if (goal.isCompleted)
                                  Icon(
                                    Icons.check_circle,
                                    color: AppColors.success,
                                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                                  ),
                                // Add Adjust Progress IconButton
                                IconButton(
                                  icon: Icon(Icons.tune, color: AppColors.info),
                                  tooltip: 'Adjust Progress',
                                  onPressed: () => _showAdjustProgressDialog(goal),
                                ),
                              ],
                            ),
                            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: AppColors.borderLight,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                            ),
                            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                            Text(
                              '${goal.currentAmount.toStringAsFixed(1)} / ${goal.targetAmount.toStringAsFixed(1)} ${goal.unit}',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                                fontWeight: FontWeight.w500,
                              ),
                                ),
                                Text(
                                  '${(progress * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                            Text(
                              '${_formatDate(goal.startDate)} - ${_formatDate(goal.endDate)}',
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
                                  'Goal Achieved! 🎉',
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
    final methodData = disposalMethods.firstWhere(
      (m) => m['name'].toLowerCase() == method.toLowerCase(),
      orElse: () => {'color': AppColors.mutedText}
    );
    return methodData['color'];
  }

  IconData _getDisposalMethodIcon(String method) {
    final methodData = disposalMethods.firstWhere(
      (m) => m['name'].toLowerCase() == method.toLowerCase(),
      orElse: () => {'icon': Icons.delete}
    );
    return methodData['icon'];
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showOnboardingDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.eco, color: AppColors.success),
            SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            Text('Welcome to Waste Tracker!'),
          ],
        ),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: StatefulBuilder(
              builder: (context, setDialogState) => Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildOnboardingStep(
                    1,
                    'Track Your Waste',
                    'Log every waste item you dispose of. Include type, amount, and disposal method.',
                    Icons.add_circle,
                  ),
                  _buildOnboardingStep(
                    2,
                    'Set Reduction Goals',
                    'Create specific goals to reduce waste in different categories.',
                    Icons.flag,
                  ),
                  _buildOnboardingStep(
                    3,
                    'Monitor Progress',
                    'View your environmental impact and track progress towards your goals.',
                    Icons.analytics,
                  ),
                  _buildOnboardingStep(
                    4,
                    'Make a Difference',
                    'Every entry helps you understand your consumption and find ways to reduce waste.',
                    Icons.eco,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) {
                Navigator.pop(context);
                setState(() => _showOnboarding = false);
              }
            },
            child: Text('Get Started'),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingStep(int number, String title, String description, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: ResponsiveHelper.getAdaptiveIconSize(context) * 1.5,
            height: ResponsiveHelper.getAdaptiveIconSize(context) * 1.5,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveIconSize(context) * 0.75),
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                ),
              ),
            ),
          ),
          SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: AppColors.primary, size: ResponsiveHelper.getAdaptiveIconSize(context)),
                    SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
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

  void _showAddEntryDialog() {
    String? selectedWasteType;
    String? selectedDisposalMethod;
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    bool isFormValid = false;
    String? validationError;

    // Quick entry templates for common waste items
    final List<Map<String, dynamic>> quickEntries = [
      {
        'name': 'Plastic Bottle',
        'type': 'Plastic',
        'method': 'Recycling',
        'amount': '0.5',
        'description': 'Standard 500ml plastic bottle',
        'icon': Icons.local_drink,
        'color': Colors.blue,
      },
      {
        'name': 'Paper Bag',
        'type': 'Paper',
        'method': 'Recycling',
        'amount': '0.1',
        'description': 'Small paper shopping bag',
        'icon': Icons.shopping_bag,
        'color': Colors.brown,
      },
      {
        'name': 'Food Scraps',
        'type': 'Organic',
        'method': 'Composting',
        'amount': '0.3',
        'description': 'Kitchen food waste',
        'icon': Icons.eco,
        'color': Colors.green,
      },
      {
        'name': 'Aluminum Can',
        'type': 'Metal',
        'method': 'Recycling',
        'amount': '0.4',
        'description': 'Standard beverage can',
        'icon': Icons.restaurant,
        'color': Colors.grey,
      },
      {
        'name': 'Glass Jar',
        'type': 'Glass',
        'method': 'Recycling',
        'amount': '0.8',
        'description': 'Medium glass container',
        'icon': Icons.wine_bar,
        'color': Colors.green,
      },
      {
        'name': 'Custom Entry',
        'type': null,
        'method': null,
        'amount': '',
        'description': 'Add your own waste item',
        'icon': Icons.add_circle,
        'color': Colors.grey,
      },
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LayoutBuilder(
        builder: (context, constraints) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: constraints.maxHeight * 0.9,
            ),
            child: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  // Validation function
                  void validateForm() {
                    bool valid = selectedWasteType != null && 
                               selectedDisposalMethod != null &&
                               amountController.text.isNotEmpty &&
                               double.tryParse(amountController.text) != null &&
                               double.tryParse(amountController.text)! > 0;
                    
                    String? error;
                    if (selectedWasteType == null) {
                      error = 'Please select a waste type';
                    } else if (selectedDisposalMethod == null) {
                      error = 'Please select a disposal method';
                    } else if (amountController.text.isEmpty) {
                      error = 'Please enter an amount';
                    } else if (double.tryParse(amountController.text) == null) {
                      error = 'Please enter a valid number';
                    } else if (double.tryParse(amountController.text)! <= 0) {
                      error = 'Amount must be greater than 0';
                    }
                    
                    setDialogState(() {
                      isFormValid = valid;
                      validationError = error;
                    });
                  }

                  return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      // Header
                    Row(
                      children: [
                        Icon(Icons.add_circle, color: AppColors.success, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
          'Add Waste Entry',
          style: TextStyle(
                              fontSize: 22,
            fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                            ),
                                ),
                                Text(
                                  'Track your waste disposal to understand your environmental impact',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Quick Entry Templates
                      Text(
                        'Quick Entry',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: quickEntries.length,
                          itemBuilder: (context, index) {
                            final entry = quickEntries[index];
                            final isSelected = selectedWasteType == entry['type'] &&
                                            selectedDisposalMethod == entry['method'] &&
                                            amountController.text == entry['amount'];
                            
                            return GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  selectedWasteType = entry['type'];
                                  selectedDisposalMethod = entry['method'];
                                  amountController.text = entry['amount'];
                                  validateForm();
                                });
                              },
                              child: Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.success.withValues(alpha: 0.1) : AppColors.surfaceBackground,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppColors.success : AppColors.borderLight,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          entry['icon'],
                                          color: entry['color'],
                                          size: 18,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            entry['name'],
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primaryText,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      entry['description'],
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: AppColors.secondaryText,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    if (entry['type'] != null)
                                      Text(
                                        '${entry['amount']} kg',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    Divider(),
                    const SizedBox(height: 10),
                      
                      // Waste Type Selection
                      Text.rich(
                        TextSpan(
                          children: [
                            WidgetSpan(child: Icon(Icons.category, color: AppColors.primary, size: 20)),
                            TextSpan(text: '  '),
                            TextSpan(text: 'Waste Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            TextSpan(text: ' *', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBackground,
                        borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: validationError != null && selectedWasteType == null 
                                ? AppColors.error 
                                : AppColors.borderLight,
                          ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: DropdownButtonFormField<String>(
              value: selectedWasteType,
                            decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.category),
                            helperText: 'Select the type of waste you\'re disposing',
                              errorText: validationError != null && selectedWasteType == null ? validationError : null,
                          ),
                          items: wasteTypes.map<DropdownMenuItem<String>>((type) {
                            return DropdownMenuItem<String>(
                              value: type['name'] as String,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(type['icon'] as IconData, color: type['color'] as Color, size: 22),
                                    const SizedBox(width: 8),
                                  Flexible(child: Text(type['name'] as String)),
                                ],
                              ),
                            );
              }).toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                selectedWasteType = value;
                                validateForm();
                              });
                            },
                        ),
                      ),
                    ),
                      const SizedBox(height: 18),
                      
                      // Disposal Method Selection
                      Text.rich(
                        TextSpan(
                          children: [
                            WidgetSpan(child: Icon(Icons.delete_sweep, color: AppColors.primary, size: 20)),
                            TextSpan(text: '  '),
                            TextSpan(text: 'Disposal Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            TextSpan(text: ' *', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBackground,
                        borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: validationError != null && selectedDisposalMethod == null 
                                ? AppColors.error 
                                : AppColors.borderLight,
                          ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: DropdownButtonFormField<String>(
              value: selectedDisposalMethod,
                            decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.delete_sweep),
                            helperText: 'Choose how you disposed of the waste',
                              errorText: validationError != null && selectedDisposalMethod == null ? validationError : null,
                          ),
                          items: disposalMethods.map<DropdownMenuItem<String>>((method) {
                            return DropdownMenuItem<String>(
                              value: method['name'] as String,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(method['icon'] as IconData, color: method['color'] as Color, size: 22),
                                    const SizedBox(width: 8),
                                  Flexible(child: Text(method['name'] as String)),
                                ],
                              ),
                            );
              }).toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                selectedDisposalMethod = value;
                                validateForm();
                              });
                            },
                        ),
                      ),
                    ),
                      const SizedBox(height: 18),
                      
                      // Amount with Smart Suggestions
                      Text.rich(
                        TextSpan(
                          children: [
                            WidgetSpan(child: Icon(Icons.scale, color: AppColors.primary, size: 20)),
                            TextSpan(text: '  '),
                            TextSpan(text: 'Amount (kg)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            TextSpan(text: ' *', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
              controller: amountController,
              decoration: InputDecoration(
                        prefixIcon: Icon(Icons.scale, color: AppColors.primary),
                                hintText: 'e.g. 0.5',
                        helperText: 'Use a kitchen scale or estimate the weight',
                        filled: true,
                        fillColor: AppColors.surfaceBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: validationError != null && amountController.text.isEmpty 
                                        ? AppColors.error 
                                        : AppColors.borderLight,
                                  ),
                                ),
                                errorText: validationError != null && amountController.text.isEmpty ? validationError : null,
                              ),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              onChanged: (value) {
                                setDialogState(() {
                                  validateForm();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Quick amount buttons
                          ...['0.1', '0.5', '1.0'].map((amount) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: ElevatedButton(
                              onPressed: () {
                                setDialogState(() {
                                  amountController.text = amount;
                                  validateForm();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: amountController.text == amount 
                                    ? AppColors.primary 
                                    : AppColors.surfaceBackground,
                                foregroundColor: amountController.text == amount 
                                    ? AppColors.white 
                                    : AppColors.primaryText,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: const Size(0, 32),
                              ),
                              child: Text('${amount}kg', style: TextStyle(fontSize: 12)),
                            ),
                          )),
                        ],
                      ),
                      const SizedBox(height: 18),
                      
                      // Notes
                      Text.rich(
                        TextSpan(
                          children: [
                            WidgetSpan(child: Icon(Icons.note, color: AppColors.primary, size: 20)),
                            TextSpan(text: '  '),
                            TextSpan(text: 'Notes (optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                        prefixIcon: Icon(Icons.note, color: AppColors.primary),
                          hintText: 'Describe the item, condition, or special circumstances',
                          helperText: 'Optional: Add details about the waste item',
                        filled: true,
                        fillColor: AppColors.surfaceBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppColors.borderLight),
                          ),
                      ),
                      maxLines: 3,
                    ),
                      
                      // Information Cards
                    if (selectedWasteType != null) ...[
                        const SizedBox(height: 16),
                      _buildWasteTypeInfo(selectedWasteType!),
                    ],
                    if (selectedDisposalMethod != null) ...[
                      const SizedBox(height: 12),
                      _buildDisposalMethodInfo(selectedDisposalMethod!),
                    ],
                      
                      // Environmental Impact Preview
                      if (selectedWasteType != null && selectedDisposalMethod != null && amountController.text.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.eco, color: AppColors.info),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Environmental Impact',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.info,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                                                             Text(
                                 'By ${selectedDisposalMethod?.toLowerCase() ?? ''}ing ${amountController.text}kg of ${selectedWasteType?.toLowerCase() ?? ''}, you\'re making a positive environmental impact!',
                                 style: TextStyle(
                                   fontSize: 14,
                                   color: AppColors.primaryText,
                                 ),
                               ),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 24),
                      
                      // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              if (mounted) Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                              onPressed: isFormValid ? () async {
              if (selectedWasteType != null && 
                  selectedDisposalMethod != null && 
                  amountController.text.isNotEmpty &&
                  _userId != null) {
                final amount = double.tryParse(amountController.text);
                                  if (amount != null && amount > 0) {
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
                                    if (mounted) {
                    Navigator.pop(context);
                    _loadData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                                            content: Text('Waste entry added successfully! 🌱'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                                          content: Text('Failed to add waste entry: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                }
              }
                              } : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                                disabledBackgroundColor: AppColors.mutedText,
                              ),
                              child: Text(
                                isFormValid ? 'Add Entry' : 'Fill Required Fields',
                                style: TextStyle(
                                  color: isFormValid ? AppColors.white : AppColors.secondaryText,
                                ),
                              ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWasteTypeSelector(String? selectedValue, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Waste Type *',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
        DropdownButtonFormField<String>(
          value: selectedValue,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.category),
            helperText: 'Select the type of waste you\'re disposing',
          ),
                               items: wasteTypes.map<DropdownMenuItem<String>>((type) {
            return DropdownMenuItem<String>(
              value: type['name'] as String,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(type['icon'] as IconData, color: type['color'] as Color, size: 20),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                  Flexible(child: Text(type['name'] as String)),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDisposalMethodSelector(String? selectedValue, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Disposal Method *',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
        DropdownButtonFormField<String>(
          value: selectedValue,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.delete_sweep),
            helperText: 'Choose how you disposed of the waste',
          ),
                               items: disposalMethods.map<DropdownMenuItem<String>>((method) {
            return DropdownMenuItem<String>(
              value: method['name'] as String,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(method['icon'] as IconData, color: method['color'] as Color, size: 20),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                  Flexible(child: Text(method['name'] as String)),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildWasteTypeInfo(String wasteType) {
    final typeData = wasteTypes.firstWhere((type) => type['name'] == wasteType);
    return Container(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(typeData['icon'], color: typeData['color']),
              SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
              Text(
                typeData['name'],
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
          Text(
            typeData['description'],
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
              color: AppColors.secondaryText,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
          Text(
            'Impact: ${typeData['impact']}',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
              color: AppColors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
          Text(
            'Tips:',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
              fontWeight: FontWeight.w500,
            ),
          ),
          ...typeData['tips'].map<Widget>((tip) => Padding(
            padding: EdgeInsets.only(left: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
            child: Text(
              '• $tip',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                color: AppColors.secondaryText,
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDisposalMethodInfo(String disposalMethod) {
    final methodData = disposalMethods.firstWhere((method) => method['name'] == disposalMethod);
    return Container(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(methodData['icon'], color: methodData['color']),
              SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
              Text(
                methodData['name'],
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
          Text(
            methodData['description'],
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
              color: AppColors.secondaryText,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
          Text(
            'Environmental Impact: ${methodData['impact']}',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
              color: AppColors.success,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _editEntry(WasteEntry entry) {
    // Implementation for editing entry
    // This would be similar to _showAddEntryDialog but with pre-filled values
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit functionality coming soon!'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _showAddGoalDialog() {
    String? selectedGoalType;
    final targetController = TextEditingController();
    final unitController = TextEditingController(text: 'kg');
    final durationController = TextEditingController(text: '30');
    String selectedDuration = '30';
    bool isFormValid = false;
    String? validationError;

    // Predefined goal templates for easy selection
    final List<Map<String, dynamic>> goalTemplates = [
      {
        'name': 'Plastic Reduction',
        'type': 'Plastic',
        'target': '5',
        'unit': 'kg',
        'duration': '30',
        'description': 'Reduce plastic waste by 5kg this month',
        'icon': Icons.local_drink,
        'color': Colors.blue,
      },
      {
        'name': 'Paper Waste',
        'type': 'Paper',
        'target': '3',
        'unit': 'kg',
        'duration': '30',
        'description': 'Reduce paper waste by 3kg this month',
        'icon': Icons.description,
        'color': Colors.brown,
      },
      {
        'name': 'Food Waste',
        'type': 'Organic',
        'target': '2',
        'unit': 'kg',
        'duration': '30',
        'description': 'Reduce food waste by 2kg this month',
        'icon': Icons.eco,
        'color': Colors.green,
      },
      {
        'name': 'Custom Goal',
        'type': null,
        'target': '',
        'unit': 'kg',
        'duration': '30',
        'description': 'Create your own custom waste reduction goal',
        'icon': Icons.edit,
        'color': Colors.grey,
      },
    ];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => LayoutBuilder(
        builder: (context, constraints) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: constraints.maxHeight * 0.9,
            ),
            child: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  // Validation function
                  void validateForm() {
                    bool valid = selectedGoalType != null && 
                               targetController.text.isNotEmpty &&
                               double.tryParse(targetController.text) != null &&
                               double.tryParse(targetController.text)! > 0;
                    
                    String? error;
                    if (selectedGoalType == null) {
                      error = 'Please select a goal type';
                    } else if (targetController.text.isEmpty) {
                      error = 'Please enter a target amount';
                    } else if (double.tryParse(targetController.text) == null) {
                      error = 'Please enter a valid number';
                    } else if (double.tryParse(targetController.text)! <= 0) {
                      error = 'Target amount must be greater than 0';
                    }
                    
                    setDialogState(() {
                      isFormValid = valid;
                      validationError = error;
                    });
                  }

                  return Column(
          mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                      // Header with progress indicator
                  Row(
                    children: [
                      Icon(Icons.flag, color: AppColors.primary, size: 28),
                      const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create Waste Reduction Goal',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryText,
                                  ),
                                ),
                                Text(
                                  'Set a realistic, measurable goal to reduce your waste!',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Goal Templates Section
                      Text(
                        'Quick Start Templates',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: goalTemplates.length,
                          itemBuilder: (context, index) {
                            final template = goalTemplates[index];
                            final isSelected = selectedGoalType == template['type'] &&
                                            targetController.text == template['target'] &&
                                            unitController.text == template['unit'];
                            
                            return GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  selectedGoalType = template['type'];
                                  targetController.text = template['target'];
                                  unitController.text = template['unit'];
                                  selectedDuration = template['duration'];
                                  durationController.text = template['duration'];
                                  validateForm();
                                });
                              },
                              child: Container(
                                width: 140,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceBackground,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.borderLight,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          template['icon'],
                                          color: template['color'],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                                            template['name'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primaryText,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                                    const SizedBox(height: 6),
                                    Text(
                                      template['description'],
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.secondaryText,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    if (template['type'] != null)
                                      Text(
                                        '${template['target']} ${template['unit']} in ${template['duration']} days',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                  Divider(),
                  const SizedBox(height: 10),
                      
                      // Goal Type Selection
                  Text.rich(
                    TextSpan(
                      children: [
                        WidgetSpan(child: Icon(Icons.category, color: AppColors.primary, size: 20)),
                        TextSpan(text: '  '),
                        TextSpan(text: 'Goal Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        TextSpan(text: ' *', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                      const SizedBox(height: 8),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBackground,
                      borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: validationError != null && selectedGoalType == null 
                                ? AppColors.error 
                                : AppColors.borderLight,
                          ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: DropdownButtonFormField<String>(
              value: selectedGoalType,
                            decoration: InputDecoration(
                          border: InputBorder.none,
                              helperText: 'Choose what type of waste to reduce',
                              errorText: validationError != null && selectedGoalType == null ? validationError : null,
                        ),
                        items: wasteTypes.map<DropdownMenuItem<String>>((type) {
                          return DropdownMenuItem<String>(
                            value: type['name'] as String,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(type['icon'] as IconData, color: type['color'] as Color, size: 22),
                                    const SizedBox(width: 8),
                                Flexible(child: Text(type['name'] as String)),
                              ],
                            ),
                          );
              }).toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                selectedGoalType = value;
                                validateForm();
                              });
                            },
            ),
                    ),
                  ),
                  const SizedBox(height: 18),
                      
                      // Target Amount with Smart Suggestions
                  Text.rich(
                    TextSpan(
                      children: [
                        WidgetSpan(child: Icon(Icons.track_changes, color: AppColors.primary, size: 20)),
                        TextSpan(text: '  '),
                        TextSpan(text: 'Target Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        TextSpan(text: ' *', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                      const SizedBox(height: 8),
            TextField(
              controller: targetController,
              decoration: InputDecoration(
                      hintText: 'e.g. 5',
                          helperText: 'Set your target reduction amount',
                      prefixIcon: Icon(Icons.track_changes, color: AppColors.primary),
                      filled: true,
                      fillColor: AppColors.surfaceBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: validationError != null && targetController.text.isEmpty 
                                  ? AppColors.error 
                                  : AppColors.borderLight,
                            ),
                          ),
                          errorText: validationError != null && targetController.text.isEmpty ? validationError : null,
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        onChanged: (value) {
                          setDialogState(() {
                            validateForm();
                          });
                        },
            ),
                  const SizedBox(height: 18),
                      
                      // Unit Selection with Common Options
                  Text.rich(
                    TextSpan(
                      children: [
                        WidgetSpan(child: Icon(Icons.straighten, color: AppColors.primary, size: 20)),
                        TextSpan(text: '  '),
                        TextSpan(text: 'Unit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
              controller: unitController,
              decoration: InputDecoration(
                      hintText: 'e.g. kg',
                                helperText: 'Unit of measurement',
                      prefixIcon: Icon(Icons.straighten, color: AppColors.primary),
                      filled: true,
                      fillColor: AppColors.surfaceBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: AppColors.borderLight),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Quick unit buttons
                          ...['kg', 'lbs', 'items'].map((unit) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: ElevatedButton(
                              onPressed: () {
                                setDialogState(() {
                                  unitController.text = unit;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: unitController.text == unit 
                                    ? AppColors.primary 
                                    : AppColors.surfaceBackground,
                                foregroundColor: unitController.text == unit 
                                    ? AppColors.white 
                                    : AppColors.primaryText,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: const Size(0, 32),
                              ),
                              child: Text(unit, style: TextStyle(fontSize: 12)),
                            ),
                          )),
                        ],
                      ),
                      const SizedBox(height: 18),
                      
                      // Duration Selection
                      Text.rich(
                        TextSpan(
                          children: [
                            WidgetSpan(child: Icon(Icons.calendar_today, color: AppColors.primary, size: 20)),
                            TextSpan(text: '  '),
                            TextSpan(text: 'Goal Duration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: durationController,
                              decoration: InputDecoration(
                                hintText: '30',
                                helperText: 'Number of days for this goal',
                                prefixIcon: Icon(Icons.calendar_today, color: AppColors.primary),
                                filled: true,
                                fillColor: AppColors.surfaceBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: AppColors.borderLight),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedDuration = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Quick duration buttons
                          ...['7', '30', '90'].map((days) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: ElevatedButton(
                              onPressed: () {
                                setDialogState(() {
                                  durationController.text = days;
                                  selectedDuration = days;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: durationController.text == days 
                                    ? AppColors.primary 
                                    : AppColors.surfaceBackground,
                                foregroundColor: durationController.text == days 
                                    ? AppColors.white 
                                    : AppColors.primaryText,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: const Size(0, 32),
                              ),
                              child: Text('${days}d', style: TextStyle(fontSize: 12)),
                            ),
                          )),
                        ],
                      ),
                      
                      // Goal Preview
                      if (selectedGoalType != null && targetController.text.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.preview, color: AppColors.success),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Goal Preview',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Reduce ${selectedGoalType} waste by ${targetController.text} ${unitController.text} in ${durationController.text} days',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primaryText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Start: ${_formatDate(DateTime.now())} • End: ${_formatDate(DateTime.now().add(Duration(days: int.tryParse(durationController.text) ?? 30)))}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                  const SizedBox(height: 24),
                      
                      // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            if (mounted) Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                              onPressed: isFormValid ? () async {
              if (selectedGoalType != null && 
                  targetController.text.isNotEmpty &&
                  _userId != null) {
                final targetAmount = double.tryParse(targetController.text);
                                  final duration = int.tryParse(durationController.text) ?? 30;
                                  if (targetAmount != null && targetAmount > 0) {
                  final goal = WasteReductionGoal(
                    key: '',
                    userId: _userId!,
                    goalType: selectedGoalType!,
                    targetAmount: targetAmount,
                    unit: unitController.text.isEmpty ? 'kg' : unitController.text,
                    startDate: DateTime.now(),
                                      endDate: DateTime.now().add(Duration(days: duration)),
                  );
                  try {
                    await WasteTrackerDAO.addWasteGoal(goal);
                                  if (mounted) {
                    Navigator.pop(context);
                    _loadData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                                            content: Text('Goal added successfully! 🎯'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                                        content: Text('Failed to add goal: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                }
              }
                              } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                                disabledBackgroundColor: AppColors.mutedText,
                              ),
                              child: Text(
                                isFormValid ? 'Create Goal' : 'Fill Required Fields',
                                style: TextStyle(
                                  color: isFormValid ? AppColors.white : AppColors.secondaryText,
                                ),
                              ),
            ),
          ),
        ],
                  ),
                ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _deleteEntry(WasteEntry entry) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete, color: AppColors.error),
            SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            Text('Delete Entry'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this ${entry.wasteType} entry? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await WasteTrackerDAO.deleteWasteEntry(entry.key);
                if (mounted) {
                Navigator.pop(context);
                _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Entry deleted successfully!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete entry: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAdjustProgressDialog(WasteReductionGoal goal) {
    double tempAmount = goal.currentAmount;
    final controller = TextEditingController(text: tempAmount.toStringAsFixed(2));
    String? errorText;
    void setAmount(double value, void Function(void Function()) setDialogState) {
      setDialogState(() {
        tempAmount = value.clamp(0, goal.targetAmount);
        controller.text = tempAmount.toStringAsFixed(2);
        errorText = null;
      });
    }
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.tune, color: AppColors.info),
            SizedBox(width: 8),
            Text('Adjust Progress'),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Set your current progress for this goal. This will update the progress bar and percentage. You can use the slider or enter a value below.',
                style: TextStyle(fontSize: 14, color: AppColors.secondaryText),
              ),
              SizedBox(height: 16),
              Text(
                'Progress is now auto-calculated from your entries. Manual adjustment is disabled.',
                style: TextStyle(fontSize: 13, color: AppColors.info),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                '${tempAmount.toStringAsFixed(2)} / ${goal.targetAmount.toStringAsFixed(2)} ${goal.unit}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              Slider(
                value: tempAmount.clamp(0, goal.targetAmount),
                min: 0,
                max: goal.targetAmount > 0 ? goal.targetAmount : 1,
                divisions: goal.targetAmount > 0 ? goal.targetAmount.ceil() : 1,
                label: tempAmount.toStringAsFixed(2),
                onChanged: null, // disabled
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Current Amount',
                        suffixText: goal.unit,
                        errorText: errorText,
                      ),
                      enabled: false, // disabled
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: AppColors.warning),
                    tooltip: 'Reset to zero',
                    onPressed: null, // disabled
                  ),
                ],
              ),
              if (errorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(errorText!, style: TextStyle(color: AppColors.error)),
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
            onPressed: () async {
              if (tempAmount < 0 || tempAmount > goal.targetAmount) {
                // Should not happen due to validation, but double check
                return;
              }
              // If setting to 100%, confirm
              if (tempAmount >= goal.targetAmount) {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Confirm Completion'),
                    content: Text('You are setting progress to 100%. Mark this goal as completed?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('No'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Yes'),
          ),
        ],
      ),
    );
                if (confirm != true) return;
              }
              final updatedGoal = WasteReductionGoal(
                key: goal.key,
                userId: goal.userId,
                goalType: goal.goalType,
                targetAmount: goal.targetAmount,
                unit: goal.unit,
                startDate: goal.startDate,
                endDate: goal.endDate,
                currentAmount: tempAmount,
                isCompleted: tempAmount >= goal.targetAmount,
              );
              try {
                await WasteTrackerDAO.updateWasteGoal(updatedGoal);
                if (mounted) {
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Progress updated!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update progress: ' + e.toString()),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
} 