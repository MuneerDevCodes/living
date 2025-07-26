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
        imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836',
      ),
      Recipe(
        title: 'Chicken Stir Fry',
        ingredients: ['Chicken', 'Vegetables', 'Soy Sauce', 'Oil'],
        steps: '1. Cook chicken\n2. Add vegetables\n3. Add sauce\n4. Serve hot',
        carbonScore: 4.2,
        imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836',
      ),
      Recipe(
        title: 'Online Avocado Toast',
        ingredients: ['Bread', 'Avocado', 'Lemon', 'Salt', 'Pepper'],
        steps: '1. Toast bread\n2. Mash avocado\n3. Spread on bread\n4. Add toppings',
        carbonScore: 1.2,
        imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836',
      ),
      Recipe(
        title: 'Quinoa Salad',
        ingredients: ['Quinoa', 'Cucumber', 'Tomatoes', 'Lemon', 'Olive Oil'],
        steps: '1. Cook quinoa\n2. Chop vegetables\n3. Mix ingredients\n4. Add dressing',
        carbonScore: 1.8,
        imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836', // Will show placeholder for this recipe
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

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant_menu,
          color: AppColors.mutedText,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildDialogPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant_menu,
          color: AppColors.mutedText,
          size: 60,
        ),
      ),
    );
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
          Footer(),
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

    // Responsive grid: 2 columns on mobile, more on larger screens
    int crossAxisCount = 2; // Default for mobile
    double width = MediaQuery.of(context).size.width;
    if (width > 900) {
      crossAxisCount = 4; // Desktop
    } else if (width > 600) {
      crossAxisCount = 3; // Tablet
    }

    return Padding(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75, // Optimized for mobile - cards are slightly taller than wide
        ),
        itemCount: filteredRecipes.length,
        itemBuilder: (context, index) {
          final recipe = filteredRecipes[index];
          final carbonCategory = _getCarbonCategory(recipe.carbonScore);
          final carbonColor = _getCarbonColor(recipe.carbonScore);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showRecipeDetail(recipe),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recipe image
                    Container(
                      height: 120, // Fixed height for consistency
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.borderLight,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: recipe.imageUrl != null
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: recipe.imageUrl!.startsWith('http')
                                  ? Image.network(
                                      recipe.imageUrl!,
                                      width: double.infinity,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return _buildPlaceholderImage();
                                      },
                                    )
                                  : Image.asset(
                                      recipe.imageUrl!,
                                      width: double.infinity,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return _buildPlaceholderImage();
                                      },
                                    ),
                            )
                          : _buildPlaceholderImage(),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title and category badge
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    recipe.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: carbonColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    carbonCategory,
                                    style: TextStyle(
                                      color: carbonColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Carbon score
                            Text(
                              'Score: ${recipe.carbonScore.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Ingredients preview
                            Text(
                              'Ingredients:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                recipe.ingredients.join(', '),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            
                            // Eco indicator
                            Row(
                              children: [
                                Icon(
                                  Icons.eco,
                                  size: 16,
                                  color: carbonColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Eco Score',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: carbonColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showRecipeDetail(Recipe recipe) {
    final carbonCategory = _getCarbonCategory(recipe.carbonScore);
    final carbonColor = _getCarbonColor(recipe.carbonScore);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        recipe.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: const CircleBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                                             // Recipe image
                       Container(
                         height: 200,
                         width: double.infinity,
                         decoration: BoxDecoration(
                           color: AppColors.borderLight,
                           borderRadius: BorderRadius.circular(15),
                         ),
                         child: recipe.imageUrl != null
                             ? ClipRRect(
                                 borderRadius: BorderRadius.circular(15),
                                 child: recipe.imageUrl!.startsWith('http')
                                     ? Image.network(
                                         recipe.imageUrl!,
                                         width: double.infinity,
                                         height: 200,
                                         fit: BoxFit.cover,
                                         errorBuilder: (context, error, stackTrace) {
                                           return _buildDialogPlaceholderImage();
                                         },
                                       )
                                     : Image.asset(
                                         recipe.imageUrl!,
                                         width: double.infinity,
                                         height: 200,
                                         fit: BoxFit.cover,
                                         errorBuilder: (context, error, stackTrace) {
                                           return _buildDialogPlaceholderImage();
                                         },
                                       ),
                               )
                             : _buildDialogPlaceholderImage(),
                       ),
                      const SizedBox(height: 20),
                      
                      // Carbon Score Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: carbonColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: carbonColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.eco,
                              color: carbonColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Carbon Score',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: carbonColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${recipe.carbonScore.toStringAsFixed(1)} - $carbonCategory',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: carbonColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Ingredients Section
                      Text(
                        'Ingredients',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: recipe.ingredients.map((ingredient) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 6, right: 12),
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    ingredient,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Steps Section
                      Text(
                        'Cooking Steps',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          recipe.steps,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Environmental Impact Badge
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: carbonColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: carbonColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.eco,
                                color: carbonColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Environmental Impact: $carbonCategory',
                                style: TextStyle(
                                  color: carbonColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 