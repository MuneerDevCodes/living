import 'package:flutter/material.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/services/product_dao.dart';
import 'package:living/models/product_model.dart';
import 'dart:convert';
import 'package:living/widgets/loader.dart';
import 'package:living/screens/product_detail_page.dart';
import 'package:living/services/category_constants.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:living/services/admin_service.dart';
import 'package:living/screens/manage_category_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  static const String routeName = '/search';

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin, WidgetsBindingObserver {
  String _query = '';
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  final List<MapEntry<String, Product>> _products = [];
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedSort = 'Relevance';
  final List<String> _sortOptions = [
    'Relevance',
    'Eco Rating: High to Low',
    'Eco Rating: Low to High',
    'Name: A to Z',
    'Name: Z to A',
  ];
  
  // Dynamic categories from Firebase
  List<Category> _dynamicCategories = [];
  bool _loadingCategories = true;
  bool _isAdmin = false;
  final AdminService _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    _fadeController.forward();
    _slideController.forward();
    
    // Load dynamic categories
    _loadCategories();
    
    // Setup real-time listener for categories
    _setupCategoryListener();
    
    // Check admin status
    _checkAdminStatus();
    
    // Add observer for app lifecycle
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _adminService.isAdmin();
    setState(() {
      _isAdmin = isAdmin;
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final snapshot = await FirebaseDatabase.instance.ref('categories').onValue.first;
      final data = snapshot.snapshot.value;
      if (data != null) {
        final map = Map<String, dynamic>.from(data as dynamic);
        final categories = <Category>[];
        map.forEach((key, value) {
          categories.add(Category.fromJson(Map<String, dynamic>.from(value)));
        });
        setState(() {
          _dynamicCategories = categories;
          _loadingCategories = false;
        });
      } else {
        setState(() => _loadingCategories = false);
      }
    } catch (e) {
      debugPrint("Error loading categories: $e");
      setState(() => _loadingCategories = false);
    }
  }

  void _setupCategoryListener() {
    FirebaseDatabase.instance.ref('categories').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null) {
        final map = Map<String, dynamic>.from(data as dynamic);
        final categories = <Category>[];
        map.forEach((key, value) {
          categories.add(Category.fromJson(Map<String, dynamic>.from(value)));
        });
        setState(() {
          _dynamicCategories = categories;
          _loadingCategories = false;
        });
      } else {
        setState(() {
          _dynamicCategories = [];
          _loadingCategories = false;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.isNotEmpty && _query.isEmpty) {
      _controller.text = args;
      setState(() => _query = args);
      fetchProducts();
    }
    super.didChangeDependencies();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh categories when app is resumed
      _loadCategories();
    }
    super.didChangeAppLifecycleState(state);
  }

  List<MapEntry<String, Product>> _applySearchAndSort(
    List<MapEntry<String, Product>> entries,
  ) {
    var filtered = entries;
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      filtered = entries.where((e) {
        final p = e.value;
        return p.name.toLowerCase().contains(q) ||
            p.category.name.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q);
      }).toList();
    }

    switch (_selectedSort) {
      case 'Eco Rating: High to Low':
        filtered.sort((a, b) => b.value.ecoRating.compareTo(a.value.ecoRating));
        break;
      case 'Eco Rating: Low to High':
        filtered.sort((a, b) => a.value.ecoRating.compareTo(b.value.ecoRating));
        break;
      case 'Name: A to Z':
        filtered.sort((a, b) => a.value.name.compareTo(b.value.name));
        break;
      case 'Name: Z to A':
        filtered.sort((a, b) => b.value.name.compareTo(a.value.name));
        break;
      default:
        break;
    }
    return filtered;
  }

  Future<void> fetchProducts() async {
    setState(() => _loading = true);
    try {
      final snapshot = await ProductDao().getProductList().onValue.first;
      final data = snapshot.snapshot.value;
      if (data != null) {
        final map = Map<String, dynamic>.from(data as dynamic);
        final products = <MapEntry<String, Product>>[];
        map.forEach((key, value) {
          final product = Product.fromJson(Map<dynamic, dynamic>.from(value));
          products.add(MapEntry(key, product));
        });
        setState(() {
          _products.clear();
          _products.addAll(products);
        });
      }
    } catch (e) {
      debugPrint("Error fetching products: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  // Get icon for category based on name
  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('eco') || name.contains('green') || name.contains('sustainable')) {
      return Icons.eco;
    } else if (name.contains('home') || name.contains('garden')) {
      return Icons.home;
    } else if (name.contains('kitchen') || name.contains('dining')) {
      return Icons.kitchen;
    } else if (name.contains('bath') || name.contains('personal') || name.contains('care')) {
      return Icons.cleaning_services;
    } else if (name.contains('clothing') || name.contains('fashion')) {
      return Icons.checkroom;
    } else if (name.contains('electronic')) {
      return Icons.devices;
    } else if (name.contains('sport') || name.contains('outdoor')) {
      return Icons.sports_soccer;
    } else if (name.contains('book') || name.contains('media')) {
      return Icons.menu_book;
    } else if (name.contains('toy') || name.contains('game')) {
      return Icons.toys;
    } else if (name.contains('health') || name.contains('wellness')) {
      return Icons.favorite;
    } else {
      return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Header.buildDrawer(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.surfaceBackground,
            ],
          ),
        ),
        child: Column(
          children: [
            const Header(),
            Expanded(
              child: Stack(
                children: [
                  if (_loading) 
                    Container(
                      color: AppColors.overlayLight,
                      child: const Center(child: Loader()),
                    ),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SingleChildScrollView(
                        padding: ResponsiveHelper.getAdaptivePadding(context),
                        child: Container(
                          constraints: ResponsiveHelper.getFlexibleConstraints(context),
                          child: _buildMainContent(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Footer(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildHeroSection(),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
        _buildSearchSection(),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
        _buildContentSection(),
      ],
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getCardPadding(context),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.search,
            size: ResponsiveHelper.getAdaptiveIconSize(context) * 2,
            color: Colors.white,
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
          Text(
            'Discover Sustainable Products',
            style: TextStyle(
              fontSize: ResponsiveHelper.getTitleFontSize(context),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.25),
          Text(
            'Find eco-friendly products that align with your sustainable lifestyle',
            style: TextStyle(
              fontSize: ResponsiveHelper.getBodyFontSize(context),
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Card(
      elevation: 8,
      shadowColor: AppColors.shadowMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
      ),
      child: Padding(
        padding: ResponsiveHelper.getCardPadding(context),
        child: Column(
          children: [
            _buildSearchField(),
            if (_query.isNotEmpty) ...[
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              _buildSortSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Search for sustainable products...',
          hintStyle: TextStyle(
            color: AppColors.mutedText,
            fontSize: ResponsiveHelper.getBodyFontSize(context),
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.search,
              color: Colors.white,
              size: ResponsiveHelper.getAdaptiveIconSize(context),
            ),
          ),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.clear,
                      color: AppColors.error,
                      size: ResponsiveHelper.getAdaptiveIconSize(context) * 0.8,
                    ),
                  ),
                  onPressed: () {
                    _controller.clear();
                    setState(() => _query = '');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.all(ResponsiveHelper.getAdaptiveSpacing(context)),
        ),
        style: TextStyle(
          fontSize: ResponsiveHelper.getBodyFontSize(context),
          color: AppColors.primaryText,
        ),
        onSubmitted: (v) {
          setState(() => _query = v);
          fetchProducts();
        },
        onChanged: (v) {
          setState(() => _query = v);
        },
      ),
    );
  }

  Widget _buildSortSection() {
    return Row(
      children: [
        Icon(
          Icons.sort,
          color: AppColors.primary,
          size: ResponsiveHelper.getAdaptiveIconSize(context),
        ),
        SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
        Text(
          'Sort by:',
          style: TextStyle(
            fontSize: ResponsiveHelper.getBodyFontSize(context),
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
            decoration: BoxDecoration(
              color: AppColors.surfaceBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderMedium),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSort,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                items: _sortOptions.map((opt) => DropdownMenuItem(
                  value: opt,
                  child: Text(
                    opt,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getBodyFontSize(context),
                      color: AppColors.primaryText,
                    ),
                  ),
                )).toList(),
                onChanged: (val) {
                  if (val != null && val != _selectedSort) {
                    setState(() => _selectedSort = val);
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection() {
    if (_query.isEmpty) {
      return _buildCategoriesSection();
    }

    final filtered = _applySearchAndSort(_products);
    if (filtered.isEmpty) {
      return _buildNoResultsSection();
    }

    return Column(
      children: [
        _buildResultsHeader(filtered.length),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
        _buildProductGrid(filtered),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
        _buildCategoriesSection(),
      ],
    );
  }

  Widget _buildResultsHeader(int count) {
    return Container(
      padding: ResponsiveHelper.getCardPadding(context),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(
            Icons.inventory_2,
            color: AppColors.primary,
            size: ResponsiveHelper.getAdaptiveIconSize(context),
          ),
          SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
          Text(
            '$count product${count == 1 ? '' : 's'} found',
            style: TextStyle(
              fontSize: ResponsiveHelper.getSubtitleFontSize(context),
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsSection() {
    return Card(
      elevation: 4,
      shadowColor: AppColors.shadowLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
      ),
      child: Padding(
        padding: ResponsiveHelper.getCardPadding(context),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: ResponsiveHelper.getAdaptiveIconSize(context) * 2,
              color: AppColors.mutedText,
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: ResponsiveHelper.getSubtitleFontSize(context),
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
            Text(
              'Try adjusting your search terms or explore our categories below',
              style: TextStyle(
                fontSize: ResponsiveHelper.getBodyFontSize(context),
                color: AppColors.mutedText,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            _buildCategoriesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid(List<MapEntry<String, Product>> filtered) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveHelper.isMobile(context) ? 1 : 
                       ResponsiveHelper.isTablet(context) ? 2 : 3,
        mainAxisSpacing: ResponsiveHelper.getAdaptiveSpacing(context),
        crossAxisSpacing: ResponsiveHelper.getAdaptiveSpacing(context),
        childAspectRatio: ResponsiveHelper.isMobile(context) ? 3.5 : 2.8,
      ),
      itemBuilder: (context, i) {
        final entry = filtered[i];
        return _buildProductCard(entry.value, entry.key);
      },
    );
  }

  Widget _buildProductCard(Product product, String key) {
    return Card(
      elevation: 4,
      shadowColor: AppColors.shadowLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(productKey: key),
            ),
          );
        },
        child: Container(
          padding: ResponsiveHelper.getCardPadding(context),
          child: Row(
            children: [
              _buildProductImage(product),
              SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getBodyFontSize(context),
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.25),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5,
                        vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.25,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        product.category.name,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getBodyFontSize(context) * 0.8,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                    Row(
                      children: [
                        Icon(
                          Icons.eco,
                          color: AppColors.success,
                          size: ResponsiveHelper.getAdaptiveIconSize(context) * 0.8,
                        ),
                        SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.25),
                        Text(
                          '${product.ecoRating.toStringAsFixed(1)}★',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getBodyFontSize(context),
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.mutedText,
                size: ResponsiveHelper.getAdaptiveIconSize(context) * 0.8,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    final imageSize = ResponsiveHelper.isMobile(context) ? 60.0 : 80.0;
    
    Widget imageWidget;
    if (product.imageUrl.isNotEmpty) {
      try {
        final imageBytes = base64Decode(product.imageUrl);
        imageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.4),
          child: Image.memory(
            imageBytes,
            width: imageSize,
            height: imageSize,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {
        imageWidget = _buildPlaceholderImage(imageSize);
      }
    } else {
      imageWidget = _buildPlaceholderImage(imageSize);
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.4),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: imageWidget,
    );
  }

  Widget _buildPlaceholderImage(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.4),
      ),
      child: Icon(
        Icons.image,
        color: AppColors.mutedText,
        size: ResponsiveHelper.getAdaptiveIconSize(context),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.getAdaptiveSpacing(context),
            vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5,
          ),
          child: Row(
            children: [
              Icon(
                Icons.category,
                color: AppColors.primary,
                size: ResponsiveHelper.getAdaptiveIconSize(context),
              ),
              SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
              Text(
                'Explore Categories',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getSubtitleFontSize(context),
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const Spacer(),
              if (_loadingCategories)
                SizedBox(
                  width: ResponsiveHelper.getAdaptiveIconSize(context),
                  height: ResponsiveHelper.getAdaptiveIconSize(context),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
              else ...[
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: AppColors.primary,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                  ),
                  onPressed: _loadCategories,
                  tooltip: 'Refresh categories',
                ),
                if (_isAdmin)
                  IconButton(
                    icon: Icon(
                      Icons.admin_panel_settings,
                      color: AppColors.primary,
                      size: ResponsiveHelper.getAdaptiveIconSize(context),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageCategoryPage(),
                        ),
                      );
                    },
                    tooltip: 'Manage categories',
                  ),
              ],
            ],
          ),
        ),
        _dynamicCategories.isEmpty && !_loadingCategories
            ? _buildDefaultCategories()
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _dynamicCategories.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: ResponsiveHelper.isMobile(context) ? 2 : 
                                 ResponsiveHelper.isTablet(context) ? 3 : 4,
                  mainAxisSpacing: ResponsiveHelper.getAdaptiveSpacing(context),
                  crossAxisSpacing: ResponsiveHelper.getAdaptiveSpacing(context),
                  childAspectRatio: ResponsiveHelper.isMobile(context) ? 1.2 : 1.5,
                ),
                itemBuilder: (context, i) {
                  final cat = _dynamicCategories[i];
                  return _buildCategoryCard(cat);
                },
              ),
      ],
    );
  }

  Widget _buildCategoryCard(Category cat) {
    return Card(
      elevation: 2,
      shadowColor: AppColors.shadowLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
        onTap: () {
          _controller.text = cat.name;
          setState(() => _query = cat.name);
          fetchProducts();
        },
        child: Container(
          padding: ResponsiveHelper.getCardPadding(context),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                             colors: [
                 AppColors.primary.withValues(alpha: 0.05),
                 AppColors.secondary.withValues(alpha: 0.05),
               ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
                ),
                child: Icon(
                  _getCategoryIcon(cat.name),
                  color: AppColors.primary,
                  size: ResponsiveHelper.getAdaptiveIconSize(context) * 1.2,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
              Text(
                cat.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveHelper.getBodyFontSize(context),
                  color: AppColors.primaryText,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultCategories() {
    return Column(
      children: [
        Container(
          padding: ResponsiveHelper.getCardPadding(context),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.warning,
                size: ResponsiveHelper.getAdaptiveIconSize(context),
              ),
              SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
              Expanded(
                child: Text(
                  'No categories found. Please add categories in the admin panel.',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getBodyFontSize(context),
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: kProductCategories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: ResponsiveHelper.isMobile(context) ? 2 : 
                           ResponsiveHelper.isTablet(context) ? 3 : 4,
            mainAxisSpacing: ResponsiveHelper.getAdaptiveSpacing(context),
            crossAxisSpacing: ResponsiveHelper.getAdaptiveSpacing(context),
            childAspectRatio: ResponsiveHelper.isMobile(context) ? 1.2 : 1.5,
          ),
          itemBuilder: (context, i) {
            final cat = kProductCategories[i];
            return Card(
              elevation: 2,
              shadowColor: AppColors.shadowLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
                onTap: () {
                  _controller.text = cat.label;
                  setState(() => _query = cat.label);
                  fetchProducts();
                },
                child: Container(
                  padding: ResponsiveHelper.getCardPadding(context),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.05),
                        AppColors.secondary.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
                        ),
                        child: Icon(
                          cat.icon,
                          color: AppColors.primary,
                          size: ResponsiveHelper.getAdaptiveIconSize(context) * 1.2,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                      Text(
                        cat.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveHelper.getBodyFontSize(context),
                          color: AppColors.primaryText,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
