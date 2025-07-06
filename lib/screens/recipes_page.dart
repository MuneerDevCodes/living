import 'package:flutter/material.dart';
import 'package:living/models/recipe_model.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/widgets/alert_error.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  List<Recipe> recipes = [];
  bool isLoading = true;
  String selectedCategory = 'All';

  final List<String> categories = [
    'All',
    'Low Carbon',
    'Medium Carbon',
    'High Carbon',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);
      // For now, we'll create some sample recipes since the DAO doesn't have getAllRecipes method
      recipes = _getSampleRecipes();
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertError('Failed to load recipes: $e'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  List<Recipe> _getSampleRecipes() {
    return [
      Recipe(
        title: 'Vegetarian Pasta',
        ingredients: ['Pasta', 'Tomatoes', 'Olive Oil', 'Garlic', 'Basil'],
        steps: '1. Boil pasta\n2. Sauté garlic\n3. Add tomatoes\n4. Combine and serve',
        carbonScore: 2.5,
      ),
      Recipe(
        title: 'Chicken Stir Fry',
        ingredients: ['Chicken', 'Vegetables', 'Soy Sauce', 'Oil'],
        steps: '1. Cook chicken\n2. Add vegetables\n3. Add sauce\n4. Serve hot',
        carbonScore: 4.2,
      ),
      Recipe(
        title: 'Quinoa Salad',
        ingredients: ['Quinoa', 'Cucumber', 'Tomatoes', 'Lemon', 'Olive Oil'],
        steps: '1. Cook quinoa\n2. Chop vegetables\n3. Mix ingredients\n4. Add dressing',
        carbonScore: 1.8,
      ),
    ];
  }

  List<Recipe> get filteredRecipes {
    if (selectedCategory == 'All') {
      return recipes;
    }
    // Filter based on carbon score ranges
    switch (selectedCategory) {
      case 'Low Carbon':
        return recipes.where((recipe) => recipe.carbonScore < 2.5).toList();
      case 'Medium Carbon':
        return recipes.where((recipe) => recipe.carbonScore >= 2.5 && recipe.carbonScore < 4.0).toList();
      case 'High Carbon':
        return recipes.where((recipe) => recipe.carbonScore >= 4.0).toList();
      default:
        return recipes;
    }
  }

  String _getCarbonCategory(double carbonScore) {
    if (carbonScore < 2.5) return 'Low Carbon';
    if (carbonScore < 4.0) return 'Medium Carbon';
    return 'High Carbon';
  }

  Color _getCarbonColor(double carbonScore) {
    if (carbonScore < 2.5) return AppColors.success;
    if (carbonScore < 4.0) return AppColors.warning;
    return AppColors.error;
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
                      child: _buildRecipesList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Footer(),
        ],
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

  Widget _buildRecipesList() {
    if (filteredRecipes.isEmpty) {
      return Center(
        child: Text(
          'No recipes found for this category.',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
            color: AppColors.secondaryText,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      itemCount: filteredRecipes.length,
      itemBuilder: (context, index) {
        final recipe = filteredRecipes[index];
        final carbonCategory = _getCarbonCategory(recipe.carbonScore);
        final carbonColor = _getCarbonColor(recipe.carbonScore);

        return Card(
          margin: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context)),
          child: InkWell(
            onTap: () => _showRecipeDetail(recipe),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recipe image placeholder
                Container(
                  height: ResponsiveHelper.getScreenHeight(context) * 0.25,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.2),
                    ),
                  ),
                  child: Icon(
                    Icons.restaurant,
                    color: AppColors.mutedText,
                    size: ResponsiveHelper.getAdaptiveIconSize(context) * 3,
                  ),
                ),
                Padding(
                  padding: ResponsiveHelper.getAdaptivePadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              recipe.title,
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4,
                              vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2,
                            ),
                            decoration: BoxDecoration(
                              color: carbonColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.6,
                              ),
                            ),
                            child: Text(
                              carbonCategory,
                              style: TextStyle(
                                color: carbonColor,
                                fontWeight: FontWeight.w500,
                                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                      Text(
                        'Carbon Score: ${recipe.carbonScore.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                          color: AppColors.secondaryText,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                      Text(
                        'Ingredients: ${recipe.ingredients.join(', ')}',
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
                            Icons.eco,
                            size: ResponsiveHelper.getAdaptiveIconSize(context),
                            color: carbonColor,
                          ),
                          SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                          Text(
                            'Carbon Footprint',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                              color: carbonColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRecipeDetail(Recipe recipe) {
    final carbonCategory = _getCarbonCategory(recipe.carbonScore);
    final carbonColor = _getCarbonColor(recipe.carbonScore);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          recipe.title,
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
              Container(
                height: ResponsiveHelper.getScreenHeight(context) * 0.2,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getAdaptiveBorderRadius(context),
                  ),
                ),
                child: Icon(
                  Icons.restaurant,
                  color: AppColors.mutedText,
                  size: ResponsiveHelper.getAdaptiveIconSize(context) * 2,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Text(
                'Carbon Score:',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
              Text(
                '${recipe.carbonScore.toStringAsFixed(1)} - $carbonCategory',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  color: carbonColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Text(
                'Ingredients:',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
              ...recipe.ingredients.map((ingredient) => Padding(
                padding: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.1),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        color: AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        ingredient,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Text(
                'Steps:',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
              Text(
                recipe.steps,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  color: AppColors.secondaryText,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4,
                  vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2,
                ),
                decoration: BoxDecoration(
                  color: carbonColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.6,
                  ),
                  border: Border.all(color: carbonColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.eco,
                      color: carbonColor,
                      size: ResponsiveHelper.getAdaptiveIconSize(context),
                    ),
                    SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                    Text(
                      'Environmental Impact',
                      style: TextStyle(
                        color: carbonColor,
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                      ),
                    ),
                  ],
                ),
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
} 