import 'package:flutter/material.dart';
import 'package:living/models/eco_travel_model.dart';
import 'package:living/services/eco_travel_dao.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/widgets/alert_error.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';

class EcoTravelPage extends StatefulWidget {
  const EcoTravelPage({super.key});

  @override
  State<EcoTravelPage> createState() => _EcoTravelPageState();
}

class _EcoTravelPageState extends State<EcoTravelPage> {
  List<EcoTravelSuggestion> suggestions = [];
  bool isLoading = true;
  String selectedCategory = 'All';

  final List<String> categories = [
    'All',
    'Transportation',
    'Accommodation',
    'Activities',
    'Food & Dining',
    'Shopping',
    'Local Experiences',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);
      suggestions = await EcoTravelDAO.getAllEcoTravelSuggestions();
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertError('Failed to load eco-travel suggestions: $e'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  List<EcoTravelSuggestion> get filteredSuggestions {
    if (selectedCategory == 'All') {
      return suggestions;
    }
    return suggestions.where((suggestion) => suggestion.category == selectedCategory).toList();
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
                Column(
                  children: [
                    _buildCategoryFilter(),
                    Expanded(
                      child: _buildSuggestionsList(),
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
        onPressed: _showAddSuggestionDialog,
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

  Widget _buildSuggestionsList() {
    if (filteredSuggestions.isEmpty) {
      return Center(
        child: Text(
          'No eco-travel suggestions found for this category.',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
            color: AppColors.secondaryText,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      itemCount: filteredSuggestions.length,
      itemBuilder: (context, index) {
        final suggestion = filteredSuggestions[index];
        return _buildSuggestionCard(suggestion);
      },
    );
  }

  Widget _buildSuggestionCard(EcoTravelSuggestion suggestion) {
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context)),
      child: InkWell(
        onTap: () => _showSuggestionDetail(suggestion),
        child: Padding(
          padding: ResponsiveHelper.getAdaptivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      suggestion.title,
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
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3,
                      ),
                    ),
                    child: Text(
                      suggestion.category,
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
              Text(
                suggestion.description,
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
                    color: suggestion.isVerified ? AppColors.success : AppColors.warning,
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                  Text(
                    suggestion.isVerified ? 'Verified' : 'Pending Verification',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                      color: suggestion.isVerified ? AppColors.success : AppColors.warning,
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
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3,
                      ),
                      border: Border.all(color: AppColors.info.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud,
                          color: AppColors.info,
                          size: ResponsiveHelper.getAdaptiveIconSize(context),
                        ),
                        SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.1),
                        Text(
                          '${suggestion.carbonImpact.toStringAsFixed(1)} ${suggestion.carbonUnit}',
                          style: TextStyle(
                            color: AppColors.info,
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

  // Color _getDifficultyColor(String difficulty) {
  //   switch (difficulty.toLowerCase()) {
  //     case 'easy':
  //       return AppColors.success;
  //     case 'medium':
  //       return AppColors.warning;
  //     case 'hard':
  //       return AppColors.error;
  //     default:
  //       return AppColors.mutedText;
  //   }
  // }

  void _showSuggestionDetail(EcoTravelSuggestion suggestion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          suggestion.title,
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
                suggestion.description,
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
                    color: suggestion.isVerified ? AppColors.success : AppColors.warning,
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                  Text(
                    suggestion.isVerified ? 'Verified Suggestion' : 'Pending Verification',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      color: suggestion.isVerified ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Row(
                children: [
                  Icon(
                    Icons.cloud,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                    color: AppColors.info,
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                  Text(
                    'Carbon Reduction: ${suggestion.carbonImpact.toStringAsFixed(1)} ${suggestion.carbonUnit} per trip',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      color: AppColors.info,
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
                    'Category: ${suggestion.category}',
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
                    'Location: ${suggestion.location}',
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

  void _showAddSuggestionDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'Transportation';
    String selectedDifficulty = 'Easy';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add Eco-Travel Suggestion',
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
                  labelText: 'Suggestion Title',
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
              // Add suggestion logic here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Eco-Travel suggestion added successfully!',
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
              'Add Suggestion',
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