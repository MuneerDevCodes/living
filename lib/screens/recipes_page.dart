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
        steps:
            '1. Boil pasta\n2. Sauté garlic\n3. Add tomatoes\n4. Combine and serve',
        carbonScore: 2.5,
        imageUrl: 'assets/images/pasta.png',
      ),
      Recipe(
        title: 'Chicken Stir Fry',
        ingredients: ['Chicken', 'Vegetables', 'Soy Sauce', 'Oil'],
        steps: '1. Cook chicken\n2. Add vegetables\n3. Add sauce\n4. Serve hot',
        carbonScore: 4.2,
        imageUrl: 'assets/images/fry.png',
      ),
      Recipe(
        title: 'Quinoa Salad',
        ingredients: ['Quinoa', 'Cucumber', 'Tomatoes', 'Lemon', 'Olive Oil'],
        steps:
            '1. Cook quinoa\n2. Chop vegetables\n3. Mix ingredients\n4. Add dressing',
        carbonScore: 1.8,
        imageUrl:
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS4NfN1ccro_mGL1Ng4uLX8W8fFs5EdvtGveg&s',
      ),
      Recipe(
        title: 'Lentil Soup',
        ingredients: [
          'Lentils',
          'Carrots',
          'Celery',
          'Onion',
          'Garlic',
          'Spices',
        ],
        steps:
            '1. Sauté vegetables\n2. Add lentils and water\n3. Simmer until soft\n4. Blend and serve',
        carbonScore: 1.2,
        imageUrl:
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQRtn5Rfg9-92oxMw1CDvgs8adBcQAaNBO5AA&s',
      ),
      Recipe(
        title: 'Beef Tacos',
        ingredients: [
          'Ground Beef',
          'Taco Shells',
          'Lettuce',
          'Tomatoes',
          'Cheese',
        ],
        steps:
            '1. Cook beef\n2. Prepare toppings\n3. Fill tacos\n4. Serve with salsa',
        carbonScore: 5.0,
        imageUrl:
            'https://media.istockphoto.com/id/1413248571/photo/two-tacos-with-ground-beef-and-lime-on-white-background.jpg?s=612x612&w=0&k=20&c=QJC5RzLFTdavb_Zu56vkaspg4a00rYv9nqTxSPCtdq8=',
      ),
      Recipe(
        title: 'Avocado Toast',
        ingredients: [
          'Bread',
          'Avocado',
          'Lemon Juice',
          'Salt',
          'Chili Flakes',
        ],
        steps:
            '1. Toast bread\n2. Mash avocado\n3. Spread and season\n4. Serve immediately',
        carbonScore: 2.0,
        imageUrl:
            'data:image/jpeg;base64,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',
      ),
    ];
  }

  List<Recipe> get filteredRecipes {
    if (selectedCategory == 'All') return recipes;
    switch (selectedCategory) {
      case 'Low Carbon':
        return recipes.where((r) => r.carbonScore < 2.5).toList();
      case 'Medium Carbon':
        return recipes
            .where((r) => r.carbonScore >= 2.5 && r.carbonScore < 4.0)
            .toList();
      case 'High Carbon':
        return recipes.where((r) => r.carbonScore >= 4.0).toList();
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
                    Expanded(child: _buildRecipesList()),
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
            margin: EdgeInsets.only(
              right: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4,
            ),
            child: FilterChip(
              label: Text(
                category,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(
                    context,
                    baseSize: 14,
                  ),
                ),
              ),
              selected: isSelected,
              onSelected: (_) {
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
            fontSize: ResponsiveHelper.getAdaptiveFontSize(
              context,
              baseSize: 16,
            ),
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
        final carbonColor = _getCarbonColor(recipe.carbonScore);
        final carbonCategory = _getCarbonCategory(recipe.carbonScore);

        return Card(
          margin: EdgeInsets.only(
            bottom: ResponsiveHelper.getAdaptiveSpacing(context),
          ),
          child: InkWell(
            onTap: () => _showRecipeDetail(recipe),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(
                      ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.2,
                    ),
                  ),
                  child: Image.network(
                    recipe.imageUrl,
                    height: ResponsiveHelper.getScreenHeight(context) * 0.25,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Icon(
                          Icons.restaurant,
                          color: AppColors.mutedText,
                          size:
                              ResponsiveHelper.getAdaptiveIconSize(context) * 3,
                        ),
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
                                fontSize: ResponsiveHelper.getAdaptiveFontSize(
                                  context,
                                  baseSize: 18,
                                ),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  ResponsiveHelper.getAdaptiveSpacing(context) *
                                  0.4,
                              vertical:
                                  ResponsiveHelper.getAdaptiveSpacing(context) *
                                  0.2,
                            ),
                            decoration: BoxDecoration(
                              color: carbonColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                ResponsiveHelper.getAdaptiveBorderRadius(
                                      context,
                                    ) *
                                    0.6,
                              ),
                            ),
                            child: Text(
                              carbonCategory,
                              style: TextStyle(
                                color: carbonColor,
                                fontWeight: FontWeight.w500,
                                fontSize: ResponsiveHelper.getAdaptiveFontSize(
                                  context,
                                  baseSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height:
                            ResponsiveHelper.getAdaptiveSpacing(context) * 0.4,
                      ),
                      Text(
                        'Carbon Score: ${recipe.carbonScore.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(
                            context,
                            baseSize: 14,
                          ),
                          color: AppColors.secondaryText,
                        ),
                      ),
                      SizedBox(
                        height:
                            ResponsiveHelper.getAdaptiveSpacing(context) * 0.4,
                      ),
                      Text(
                        'Ingredients: ${recipe.ingredients.join(', ')}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(
                            context,
                            baseSize: 14,
                          ),
                          color: AppColors.secondaryText,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(
                        height:
                            ResponsiveHelper.getAdaptiveSpacing(context) * 0.4,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.eco,
                            size: ResponsiveHelper.getAdaptiveIconSize(context),
                            color: carbonColor,
                          ),
                          SizedBox(
                            width:
                                ResponsiveHelper.getAdaptiveSpacing(context) *
                                0.2,
                          ),
                          Text(
                            'Carbon Footprint',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getAdaptiveFontSize(
                                context,
                                baseSize: 12,
                              ),
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
      builder:
          (context) => AlertDialog(
            title: Text(
              recipe.title,
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(
                  context,
                  baseSize: 18,
                ),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getAdaptiveBorderRadius(context),
                    ),
                    child: Image.network(
                      recipe.imageUrl,
                      height: ResponsiveHelper.getScreenHeight(context) * 0.2,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => Icon(
                            Icons.restaurant,
                            color: AppColors.mutedText,
                            size:
                                ResponsiveHelper.getAdaptiveIconSize(context) *
                                2,
                          ),
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveHelper.getAdaptiveSpacing(context),
                  ),
                  Text(
                    'Carbon Score:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${recipe.carbonScore.toStringAsFixed(1)} - $carbonCategory',
                    style: TextStyle(
                      color: carbonColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveHelper.getAdaptiveSpacing(context),
                  ),
                  Text(
                    'Ingredients:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...recipe.ingredients.map((i) => Text('• $i')),
                  SizedBox(
                    height: ResponsiveHelper.getAdaptiveSpacing(context),
                  ),
                  Text('Steps:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(recipe.steps),
                  SizedBox(
                    height: ResponsiveHelper.getAdaptiveSpacing(context),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          ResponsiveHelper.getAdaptiveSpacing(context) * 0.4,
                      vertical:
                          ResponsiveHelper.getAdaptiveSpacing(context) * 0.2,
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
                        SizedBox(
                          width:
                              ResponsiveHelper.getAdaptiveSpacing(context) *
                              0.2,
                        ),
                        Text(
                          'Environmental Impact',
                          style: TextStyle(
                            color: carbonColor,
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(
                              context,
                              baseSize: 12,
                            ),
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
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(
                      context,
                      baseSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
