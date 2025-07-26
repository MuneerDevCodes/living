import 'package:flutter/material.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';
import 'package:living/services/energy_tip_dao.dart';
import 'package:living/services/admin_service.dart';
import 'package:living/models/energy_tip_model.dart';

/// EnergyTipsPage displays energy-saving tips, using responsive and theme-driven design.
class EnergyTipsPage extends StatefulWidget {
  const EnergyTipsPage({super.key});

  @override
  State<EnergyTipsPage> createState() => _EnergyTipsPageState();
}

class _EnergyTipsPageState extends State<EnergyTipsPage> {
  List<EnergyTip> tips = [];
  bool isLoading = true;
  String selectedCategory = 'All';
  bool isAdmin = false;

  final List<String> categories = [
    'All',
    'Home Energy',
    'Transportation',
    'Appliances',
    'Heating & Cooling',
  ];

  @override
  void initState() {
    super.initState();
    _initAdminAndLoad();
  }

  Future<void> _initAdminAndLoad() async {
    final admin = await AdminService().isAdmin();
    if (mounted) {
      setState(() {
        isAdmin = admin;
      });
    }
    await _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);
      // Load only verified tips for users
      final allTips = await EnergyTipDAO.getAllEnergyTips();
      tips = allTips.where((tip) => tip.isVerified).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load energy tips: $e',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  List<EnergyTip> _getSampleTips() {
    return [
      EnergyTip(
        key: '',
        title: 'Switch to LED Bulbs',
        description: 'Replace traditional incandescent bulbs with energy-efficient LED bulbs to save up to 80% on lighting costs.',
        category: 'Home Energy',
        difficulty: 'Easy',
        potentialSavings: 15.5,
        savingsUnit: 'kWh',
        steps: [],
        imageUrl: '',
        isVerified: true,
      ),
      EnergyTip(
        key: '',
        title: 'Unplug Unused Electronics',
        description: 'Unplug chargers and electronics when not in use to prevent phantom energy consumption.',
        category: 'Appliances',
        difficulty: 'Easy',
        potentialSavings: 8.2,
        savingsUnit: 'kWh',
        steps: [],
        imageUrl: '',
        isVerified: true,
      ),
      EnergyTip(
        key: '',
        title: 'Use Public Transportation',
        description: 'Take public transportation or carpool to reduce your carbon footprint and save on fuel costs.',
        category: 'Transportation',
        difficulty: 'Medium',
        potentialSavings: 25.0,
        savingsUnit: 'kWh',
        steps: [],
        imageUrl: '',
        isVerified: false,
      ),
      EnergyTip(
        key: '',
        title: 'Install Smart Thermostat',
        description: 'Use a programmable thermostat to automatically adjust temperature settings and save energy.',
        category: 'Heating & Cooling',
        difficulty: 'Medium',
        potentialSavings: 12.8,
        savingsUnit: 'kWh',
        steps: [],
        imageUrl: '',
        isVerified: true,
      ),
    ];
  }

  List<EnergyTip> get filteredTips {
    if (selectedCategory == 'All') {
      return tips;
    }
    return tips.where((tip) => tip.category == selectedCategory).toList();
  }

  /// Build method for the energy tips page, using only ResponsiveHelper and AppTheme/AppColors.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                    _buildCategoryFilter(),
                    Expanded(
                      child: _buildTipsList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Footer(),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: ResponsiveHelper.getBottomNavHeight(context) + 12,
        ),
        child: FloatingActionButton(
          onPressed: _showAddTipDialog,
          backgroundColor: AppColors.success,
          foregroundColor: AppColors.white,
          child: Icon(
            Icons.add,
            size: ResponsiveHelper.getAdaptiveIconSize(context),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: ResponsiveHelper.getScreenHeight(context) * 0.08,
      padding: ResponsiveHelper.getVerticalPadding(context),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: ResponsiveHelper.getHorizontalPadding(context),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return Container(
            margin: EdgeInsets.only(right: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
            child: FilterChip(
              label: Text(
                category,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedCategory = category;
                });
              },
              selectedColor: AppColors.success,
              checkmarkColor: AppColors.white,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTipsList() {
    if (filteredTips.isEmpty) {
      return Center(
        child: Text(
          'No energy tips found for this category.',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
            color: AppColors.secondaryText,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      itemCount: filteredTips.length,
      itemBuilder: (context, index) {
        final tip = filteredTips[index];
        return _buildTipCard(tip);
      },
    );
  }

  Widget _buildTipCard(EnergyTip tip) {
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context)),
      child: InkWell(
        onTap: () => _showTipDetail(tip),
        child: Padding(
          padding: ResponsiveHelper.getAdaptivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tip.title,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3,
                      vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.1,
                    ),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(tip.difficulty).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3,
                      ),
                    ),
                    child: Text(
                      tip.difficulty,
                      style: TextStyle(
                        color: _getDifficultyColor(tip.difficulty),
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isAdmin) ...[
                    IconButton(
                      icon: Icon(Icons.edit, color: AppColors.info),
                      tooltip: 'Edit',
                      onPressed: () => _showEditTipDialog(tip),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: AppColors.error),
                      tooltip: 'Delete',
                      onPressed: () => _confirmDeleteTip(tip),
                    ),
                  ],
                ],
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
              Text(
                tip.description,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  color: AppColors.secondaryText,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
              Row(
                children: [
                  Icon(
                    Icons.verified,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                    color: tip.isVerified ? AppColors.success : AppColors.warning,
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                  Text(
                    tip.isVerified ? 'Verified' : 'Pending Verification',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                      color: tip.isVerified ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3,
                      vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3,
                      ),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.savings,
                          color: AppColors.success,
                          size: ResponsiveHelper.getAdaptiveIconSize(context),
                        ),
                        SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.1),
                        Text(
                          '${tip.potentialSavings.toStringAsFixed(1)} ${tip.savingsUnit}',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'hard':
        return AppColors.error;
      default:
        return AppColors.mutedText;
    }
  }

  void _showTipDetail(EnergyTip tip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Expanded(
              child: Text(
          tip.title,
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
            fontWeight: FontWeight.bold,
          ),
              ),
            ),
            if (isAdmin) ...[
              IconButton(
                icon: Icon(Icons.edit, color: AppColors.info),
                tooltip: 'Edit',
                onPressed: () {
                  Navigator.pop(context);
                  _showEditTipDialog(tip);
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: AppColors.error),
                tooltip: 'Delete',
                onPressed: () {
                  Navigator.pop(context);
                  _confirmDeleteTip(tip);
                },
              ),
            ],
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tip.description,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  color: AppColors.secondaryText,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Row(
                children: [
                  Icon(
                    Icons.verified,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                    color: tip.isVerified ? AppColors.success : AppColors.warning,
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                  Text(
                    tip.isVerified ? 'Verified Tip' : 'Pending Verification',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      color: tip.isVerified ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Row(
                children: [
                  Icon(
                    Icons.savings,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                    color: AppColors.success,
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                  Text(
                    'Energy Savings: ${tip.potentialSavings.toStringAsFixed(1)} ${tip.savingsUnit} per month',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Row(
                children: [
                  Icon(
                    Icons.category,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                    color: AppColors.mutedText,
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                  Text(
                    'Category: ${tip.category}',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                    color: AppColors.mutedText,
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                  Text(
                    'Difficulty: ${tip.difficulty}',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      color: AppColors.secondaryText,
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
            child: Text(
              'Close',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddTipDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = categories.firstWhere((cat) => cat != 'All', orElse: () => 'Home Energy');
    String selectedDifficulty = 'Easy';

    final newTip = await showDialog<EnergyTip>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add Energy Tip',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Tip Title',
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
                maxLines: 3,
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  ),
                ),
                items: categories.where((cat) => cat != 'All').map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                )).toList(),
                onChanged: (value) {
                  selectedCategory = value!;
                },
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              DropdownButtonFormField<String>(
                value: selectedDifficulty,
                decoration: InputDecoration(
                  labelText: 'Difficulty',
                  labelStyle: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  ),
                ),
                items: [
                  'Easy',
                  'Medium',
                  'Hard',
                ].map((difficulty) => DropdownMenuItem(
                  value: difficulty,
                  child: Text(
                    difficulty,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                )).toList(),
                onChanged: (value) {
                  selectedDifficulty = value!;
                },
              ),
            ],
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
              if (titleController.text.trim().isEmpty || descriptionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Please fill in all fields.',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      ),
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              final isAdmin = await AdminService().isAdmin();
              final tip = EnergyTip(
                key: '',
                title: titleController.text.trim(),
                description: descriptionController.text.trim(),
                category: selectedCategory,
                difficulty: selectedDifficulty,
                potentialSavings: 0.0,
                savingsUnit: '',
                steps: [],
                imageUrl: '',
                isVerified: isAdmin,
              );
              await EnergyTipDAO.addEnergyTip(tip);
              Navigator.pop(context, tip);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: Text(
              'Add Tip',
              style: TextStyle(
                color: AppColors.white,
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
          ),
        ],
      ),
    );

    if (newTip != null) {
      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newTip.isVerified ? 'Energy tip added and verified!' : 'Energy tip submitted for admin approval.',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
            ),
          ),
          backgroundColor: newTip.isVerified ? AppColors.success : AppColors.warning,
        ),
      );
    }
  }

  void _showEditTipDialog(EnergyTip tip) {
    final titleController = TextEditingController(text: tip.title);
    final descriptionController = TextEditingController(text: tip.description);
    String selectedCategory = tip.category;
    String selectedDifficulty = tip.difficulty;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Energy Tip',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Tip Title',
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
                maxLines: 3,
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  ),
                ),
                items: categories.where((cat) => cat != 'All').map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                )).toList(),
                onChanged: (value) {
                  selectedCategory = value!;
                },
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              DropdownButtonFormField<String>(
                value: selectedDifficulty,
                decoration: InputDecoration(
                  labelText: 'Difficulty',
                  labelStyle: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  ),
                ),
                items: [
                  'Easy',
                  'Medium',
                  'Hard',
                ].map((difficulty) => DropdownMenuItem(
                  value: difficulty,
                  child: Text(
                    difficulty,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                )).toList(),
                onChanged: (value) {
                  selectedDifficulty = value!;
                },
              ),
            ],
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
              if (titleController.text.trim().isEmpty || descriptionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Please fill in all fields.',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      ),
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              try {
                final updatedTip = EnergyTip(
                  key: tip.key,
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  category: selectedCategory,
                  difficulty: selectedDifficulty,
                  potentialSavings: tip.potentialSavings,
                  savingsUnit: tip.savingsUnit,
                  steps: tip.steps,
                  imageUrl: tip.imageUrl,
                  isVerified: true,
                );
                await EnergyTipDAO.updateEnergyTip(updatedTip);
                await _loadData();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Energy tip updated successfully!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update energy tip: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: Text(
              'Save Changes',
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

  void _confirmDeleteTip(EnergyTip tip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Energy Tip'),
        content: Text('Are you sure you want to delete "${tip.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              try {
                await EnergyTipDAO.deleteEnergyTip(tip.key);
                await _loadData();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Energy tip deleted successfully!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete energy tip: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }
} 