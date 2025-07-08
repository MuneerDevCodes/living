import 'package:flutter/material.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';

class EnergyTip {
  final String title;
  final String description;
  final String category;
  final bool isVerified;
  final double energySavings;
  final String difficulty;

  EnergyTip({
    required this.title,
    required this.description,
    required this.category,
    required this.isVerified,
    required this.energySavings,
    required this.difficulty,
  });
}

class EnergyTipsPage extends StatefulWidget {
  const EnergyTipsPage({super.key});

  @override
  State<EnergyTipsPage> createState() => _EnergyTipsPageState();
}

class _EnergyTipsPageState extends State<EnergyTipsPage> {
  List<EnergyTip> tips = [];
  bool isLoading = true;
  String selectedCategory = 'All';

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
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);
      // Simulate loading
      await Future.delayed(const Duration(seconds: 1));
      tips = _getSampleTips();
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
        title: 'Switch to LED Bulbs',
        description: 'Replace traditional incandescent bulbs with energy-efficient LED bulbs to save up to 80% on lighting costs.',
        category: 'Home Energy',
        isVerified: true,
        energySavings: 15.5,
        difficulty: 'Easy',
      ),
      EnergyTip(
        title: 'Unplug Unused Electronics',
        description: 'Unplug chargers and electronics when not in use to prevent phantom energy consumption.',
        category: 'Appliances',
        isVerified: true,
        energySavings: 8.2,
        difficulty: 'Easy',
      ),
      EnergyTip(
        title: 'Use Public Transportation',
        description: 'Take public transportation or carpool to reduce your carbon footprint and save on fuel costs.',
        category: 'Transportation',
        isVerified: false,
        energySavings: 25.0,
        difficulty: 'Medium',
      ),
      EnergyTip(
        title: 'Install Smart Thermostat',
        description: 'Use a programmable thermostat to automatically adjust temperature settings and save energy.',
        category: 'Heating & Cooling',
        isVerified: true,
        energySavings: 12.8,
        difficulty: 'Medium',
      ),
    ];
  }

  List<EnergyTip> get filteredTips {
    if (selectedCategory == 'All') {
      return tips;
    }
    return tips.where((tip) => tip.category == selectedCategory).toList();
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTipDialog,
        backgroundColor: AppColors.success,
        foregroundColor: AppColors.white,
        child: Icon(
          Icons.add,
          size: ResponsiveHelper.getAdaptiveIconSize(context),
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
                      color: _getDifficultyColor(tip.difficulty).withOpacity(0.1),
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
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3,
                      ),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
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
                          '${tip.energySavings.toStringAsFixed(1)} kWh',
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
        title: Text(
          tip.title,
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
            fontWeight: FontWeight.bold,
          ),
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
                    'Energy Savings: ${tip.energySavings.toStringAsFixed(1)} kWh per month',
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

  void _showAddTipDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'Home Energy';
    String selectedDifficulty = 'Easy';

    showDialog(
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
            onPressed: () {
              // Add tip logic here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Energy tip added successfully!',
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
  }
} 