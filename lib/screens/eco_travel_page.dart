import 'package:flutter/material.dart';
import 'package:living/models/eco_travel_model.dart';
import 'package:living/services/eco_travel_dao.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/widgets/alert_error.dart';
import 'package:living/widgets/alert_success.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';

/// EcoTravelPage displays eco-friendly travel suggestions, using responsive and theme-driven design.
class EcoTravelPage extends StatefulWidget {
  const EcoTravelPage({super.key});

  @override
  State<EcoTravelPage> createState() => _EcoTravelPageState();
}

class _EcoTravelPageState extends State<EcoTravelPage> {
  List<EcoTravelSuggestion> suggestions = [];
  List<EcoTravelSuggestion> filteredSuggestions = [];
  bool isLoading = true;
  String selectedCategory = 'All';
  String selectedLocation = 'All';
  String searchQuery = '';
  List<String> popularDestinations = [];

  final List<String> categories = [
    'All',
    'Transportation',
    'Accommodation',
    'Activities',
    'Food & Dining',
    'Shopping',
    'Local Experiences',
  ];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);
      final data = await Future.wait([
        EcoTravelDAO.getAllEcoTravelSuggestions(),
        EcoTravelDAO.getPopularDestinations(),
      ]);
      
      suggestions = data[0] as List<EcoTravelSuggestion>;
      popularDestinations = data[1] as List<String>;
      _applyFilters();
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

  void _applyFilters() {
    filteredSuggestions = suggestions.where((suggestion) {
      final matchesCategory = selectedCategory == 'All' || suggestion.category == selectedCategory;
      final matchesLocation = selectedLocation == 'All' || suggestion.location == selectedLocation;
      final matchesSearch = searchQuery.isEmpty || 
        suggestion.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
        suggestion.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
        suggestion.location.toLowerCase().contains(searchQuery.toLowerCase());
      
      return matchesCategory && matchesLocation && matchesSearch;
    }).toList();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchQuery = '';
        _applyFilters();
      });
      return;
    }

    try {
      setState(() => isLoading = true);
      final searchResults = await EcoTravelDAO.searchEcoTravelSuggestions(query);
      setState(() {
        searchQuery = query;
        filteredSuggestions = searchResults;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertError('Search failed: $e'),
        );
      }
    }
  }

  /// Build method for the eco travel page, using only ResponsiveHelper and AppTheme/AppColors.
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
                    _buildSearchBar(),
                    _buildFilterSection(),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildSuggestionsList(),
                          ],
                        ),
                      ),
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
        child: FloatingActionButton.extended(
          onPressed: _showAddSuggestionDialog,
          backgroundColor: AppColors.success,
          foregroundColor: AppColors.white,
          icon: Icon(
            Icons.add,
            size: ResponsiveHelper.getAdaptiveIconSize(context),
          ),
          label: Text(
            'Add Suggestion',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search eco-travel suggestions...',
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.mutedText,
            size: ResponsiveHelper.getAdaptiveIconSize(context),
          ),
          suffixIcon: searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: AppColors.mutedText,
                  size: ResponsiveHelper.getAdaptiveIconSize(context),
                ),
                onPressed: () {
                  _searchController.clear();
                  _performSearch('');
                },
              )
            : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getAdaptiveBorderRadius(context),
            ),
            borderSide: BorderSide(color: AppColors.borderMedium),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getAdaptiveBorderRadius(context),
            ),
            borderSide: BorderSide(color: AppColors.primary),
          ),
        ),
        onChanged: (value) {
          if (value.isEmpty) {
            setState(() {
              searchQuery = '';
              _applyFilters();
            });
          }
        },
        onSubmitted: _performSearch,
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: ResponsiveHelper.getVerticalPadding(context),
      child: Column(
        children: [
          _buildCategoryFilter(),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
          _buildLocationFilter(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: ResponsiveHelper.getScreenHeight(context) * 0.06,
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
                  color: isSelected ? AppColors.white : AppColors.primaryText,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedCategory = category;
                  _applyFilters();
                });
              },
              selectedColor: AppColors.success,
              checkmarkColor: AppColors.white,
              backgroundColor: AppColors.background,
              side: BorderSide(color: AppColors.borderMedium),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationFilter() {
    final locations = ['All', ...popularDestinations.take(8)];
    
    return Container(
      height: ResponsiveHelper.getScreenHeight(context) * 0.06,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: ResponsiveHelper.getHorizontalPadding(context),
        itemCount: locations.length,
        itemBuilder: (context, index) {
          final location = locations[index];
          final isSelected = location == selectedLocation;

          return Container(
            margin: EdgeInsets.only(right: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
            child: FilterChip(
              label: Text(
                location,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                  color: isSelected ? AppColors.white : AppColors.primaryText,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedLocation = location;
                  _applyFilters();
                });
              },
              selectedColor: AppColors.info,
              checkmarkColor: AppColors.white,
              backgroundColor: AppColors.background,
              side: BorderSide(color: AppColors.borderMedium),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuggestionsList() {
    if (filteredSuggestions.isEmpty) {
      return Container(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.travel_explore,
                size: ResponsiveHelper.getAdaptiveIconSize(context) * 2,
                color: AppColors.mutedText,
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Text(
                searchQuery.isNotEmpty 
                  ? 'No eco-travel suggestions found for "$searchQuery"'
                  : 'No eco-travel suggestions found for this category.',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
              if (searchQuery.isNotEmpty) ...[
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                ElevatedButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      searchQuery = '';
                      selectedCategory = 'All';
                      selectedLocation = 'All';
                      _applyFilters();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: Text(
                    'Clear Search',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getAdaptiveBorderRadius(context),
        ),
      ),
      child: InkWell(
        onTap: () => _showSuggestionDetail(suggestion),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getAdaptiveBorderRadius(context),
        ),
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
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
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
                    Icons.location_on,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                    color: AppColors.info,
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                  Expanded(
                    child: Text(
                      suggestion.location,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                        color: AppColors.info,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
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
                      color: suggestion.carbonImpact < 0 
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3,
                      ),
                      border: Border.all(
                        color: suggestion.carbonImpact < 0 
                          ? AppColors.success.withValues(alpha: 0.3)
                          : AppColors.info.withValues(alpha: 0.3)
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          suggestion.carbonImpact < 0 ? Icons.trending_down : Icons.cloud,
                          color: suggestion.carbonImpact < 0 ? AppColors.success : AppColors.info,
                          size: ResponsiveHelper.getAdaptiveIconSize(context),
                        ),
                        SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.1),
                        Text(
                          '${suggestion.carbonImpact.toStringAsFixed(1)} ${suggestion.carbonUnit}',
                          style: TextStyle(
                            color: suggestion.carbonImpact < 0 ? AppColors.success : AppColors.info,
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
              
              // Location
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                    color: AppColors.info,
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                  Text(
                    suggestion.location,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      color: AppColors.info,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              
              // Carbon Impact
              Row(
                children: [
                  Icon(
                    suggestion.carbonImpact < 0 ? Icons.trending_down : Icons.cloud,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                    color: suggestion.carbonImpact < 0 ? AppColors.success : AppColors.info,
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                  Text(
                    'Carbon Impact: ${suggestion.carbonImpact.toStringAsFixed(1)} ${suggestion.carbonUnit}',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      color: suggestion.carbonImpact < 0 ? AppColors.success : AppColors.info,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              
              // Category
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
              
              // Verification Status
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
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 1.5),
              
              // Benefits Section
              if (suggestion.benefits.isNotEmpty) ...[
                Text(
                  'Benefits:',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                ...suggestion.benefits.map((benefit) => Padding(
                  padding: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: ResponsiveHelper.getAdaptiveIconSize(context),
                        color: AppColors.success,
                      ),
                      SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                      Expanded(
                        child: Text(
                          benefit,
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
              ],
              
              // Tips Section
              if (suggestion.tips.isNotEmpty) ...[
                Text(
                  'Tips:',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                ...suggestion.tips.map((tip) => Padding(
                  padding: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb,
                        size: ResponsiveHelper.getAdaptiveIconSize(context),
                        color: AppColors.warning,
                      ),
                      SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                      Expanded(
                        child: Text(
                          tip,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
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
    final locationController = TextEditingController();
    final carbonImpactController = TextEditingController();
    final carbonUnitController = TextEditingController();
    final benefitsController = TextEditingController();
    final tipsController = TextEditingController();
    
    String selectedCategory = 'Transportation';
    final formKey = GlobalKey<FormState>();

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
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Suggestion Title *',
                    labelStyle: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                TextFormField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description *',
                    labelStyle: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                TextFormField(
                  controller: locationController,
                  decoration: InputDecoration(
                    labelText: 'Location *',
                    labelStyle: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a location';
                    }
                    return null;
                  },
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category *',
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
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: carbonImpactController,
                        decoration: InputDecoration(
                          labelText: 'Carbon Impact *',
                          labelStyle: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                    Expanded(
                      child: TextFormField(
                        controller: carbonUnitController,
                        decoration: InputDecoration(
                          labelText: 'Unit (e.g., kg CO2/km) *',
                          labelStyle: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                TextFormField(
                  controller: benefitsController,
                  decoration: InputDecoration(
                    labelText: 'Benefits (comma-separated)',
                    labelStyle: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                TextFormField(
                  controller: tipsController,
                  decoration: InputDecoration(
                    labelText: 'Tips (comma-separated)',
                    labelStyle: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
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
              if (formKey.currentState!.validate()) {
                try {
                  final suggestion = EcoTravelSuggestion(
                    key: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    category: selectedCategory,
                    location: locationController.text.trim(),
                    carbonImpact: double.parse(carbonImpactController.text),
                    carbonUnit: carbonUnitController.text.trim(),
                    benefits: benefitsController.text.isNotEmpty 
                      ? benefitsController.text.split(',').map((e) => e.trim()).toList()
                      : [],
                    tips: tipsController.text.isNotEmpty 
                      ? tipsController.text.split(',').map((e) => e.trim()).toList()
                      : [],
                    imageUrl: '',
                    isVerified: false,
                  );

                  await EcoTravelDAO.addEcoTravelSuggestion(suggestion);
                  Navigator.pop(context);
                  
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertSuccess(
                        'Eco-Travel suggestion added successfully! It will be reviewed and verified soon.',
                      ),
                    );
                    _loadData(); // Reload data to show new suggestion
                  }
                } catch (e) {
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertError('Failed to add suggestion: $e'),
                    );
                  }
                }
              }
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