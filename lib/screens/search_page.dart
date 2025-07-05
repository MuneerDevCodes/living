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

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  static const String routeName = '/search';

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _query = '';
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  final List<MapEntry<String, Product>> _products = [];

  String _selectedSort = 'Relevance';
  final List<String> _sortOptions = [
    'Relevance',
    'Eco Rating: High to Low',
    'Eco Rating: Low to High',
    'Name: A to Z',
    'Name: Z to A',
  ];
  final List<ProductCategory> _categories = kProductCategories;

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

  List<MapEntry<String, Product>> _applySearchAndSort(
    List<MapEntry<String, Product>> entries,
  ) {
    var filtered = entries;
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      filtered =
          entries.where((e) {
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
        setState(
          () =>
              _products
                ..clear()
                ..addAll(products),
        );
      }
    } catch (e) {
      debugPrint("Error fetching products: $e");
    } finally {
      setState(() => _loading = false);
    }
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
                Center(
                  child: SingleChildScrollView(
                    padding: ResponsiveHelper.getAdaptivePadding(context),
                    child: Container(
                      constraints: ResponsiveHelper.getFlexibleConstraints(context),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getAdaptiveBorderRadius(context),
                          ),
                        ),
                        child: Padding(
                          padding: ResponsiveHelper.getCardPadding(context),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Search Products',
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 22),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                              _buildSearchField(),
                              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.75),
                              _buildProductList(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Footer(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: 'Enter product name, category, or keyword',
        prefixIcon: Icon(
          Icons.search,
          size: ResponsiveHelper.getAdaptiveIconSize(context),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.6,
          ),
        ),
        isDense: true,
        suffixIcon: _query.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  size: ResponsiveHelper.getAdaptiveIconSize(context),
                ),
                onPressed: () {
                  _controller.clear();
                  setState(() => _query = '');
                },
              )
            : null,
      ),
      onSubmitted: (v) {
        setState(() => _query = v);
        fetchProducts();
      },
      onChanged: (v) {
        setState(() => _query = v);
      },
    );
  }

  Widget _buildProductList() {
    if (_query.isEmpty) return _buildCategories(context);

    final filtered = _applySearchAndSort(_products);
    if (filtered.isEmpty) {
      return FutureBuilder(
        future: Future.delayed(const Duration(milliseconds: 300)),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: ResponsiveHelper.getAdaptiveSpacing(context)),
                child: Text(
                  'No results found.',
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              _buildCategories(context),
            ],
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSortSection(),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
        _buildProductListView(filtered),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
        _buildCategories(context),
      ],
    );
  }

  Widget _buildSortSection() {
    return Row(
      children: [
        Text(
          'Sort by:',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
          ),
        ),
        SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.6),
        Flexible(
          child: DropdownButton<String>(
            value: _selectedSort,
            isExpanded: true,
            items: _sortOptions
                .map(
                  (opt) => DropdownMenuItem(
                    value: opt,
                    child: Text(
                      opt,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null && val != _selectedSort) {
                setState(() => _selectedSort = val);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductListView(List<MapEntry<String, Product>> filtered) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (context, i) => Divider(
        height: ResponsiveHelper.getAdaptiveSpacing(context),
      ),
      itemBuilder: (context, i) {
        final entry = filtered[i];
        final product = entry.value;
        final key = entry.key;

        return _buildProductTile(product, key);
      },
    );
  }

  Widget _buildProductTile(Product product, String key) {
    final imageSize = ResponsiveHelper.getAdaptiveImageSize(context);
    
    Widget leadingWidget;
    if (product.imageUrl.isNotEmpty) {
      try {
        final imageBytes = base64Decode(product.imageUrl);
        leadingWidget = ClipRRect(
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.4,
          ),
          child: Image.memory(
            imageBytes,
            width: imageSize,
            height: imageSize * 1.5,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {
        leadingWidget = _placeholderImage(imageSize);
      }
    } else {
      leadingWidget = _placeholderImage(imageSize);
    }

    return ListTile(
      leading: leadingWidget,
      title: Text(
        product.name,
        style: TextStyle(
          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        product.category.name,
        style: TextStyle(
          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
        ),
      ),
      trailing: Text(
        '${product.ecoRating.toStringAsFixed(1)}★',
        style: TextStyle(
          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(productKey: key),
          ),
        );
      },
    );
  }

  Widget _placeholderImage(double size) {
    return Container(
      color: AppColors.borderLight,
      width: size,
      height: size * 1.5,
      child: Icon(
        Icons.image,
        color: AppColors.mutedText,
        size: ResponsiveHelper.getAdaptiveIconSize(context),
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5,
              top: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5,
            ),
            child: Text(
              'Explore Categories',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: ResponsiveHelper.getAdaptiveCrossAxisCount(context),
            mainAxisSpacing: ResponsiveHelper.getAdaptiveSpacing(context) * 0.6,
            crossAxisSpacing: ResponsiveHelper.getAdaptiveSpacing(context) * 0.6,
            childAspectRatio: ResponsiveHelper.getAdaptiveAspectRatio(context),
          ),
          itemBuilder: (context, i) {
            final cat = _categories[i];
            return _buildCategoryCard(cat);
          },
        ),
      ],
    );
  }

  Widget _buildCategoryCard(ProductCategory cat) {
    return Material(
      color: Theme.of(context).colorScheme.secondary.withAlpha((0.08 * 255).toInt()),
      borderRadius: BorderRadius.circular(
        ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.7,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.7,
        ),
        onTap: () {
          _controller.text = cat.label;
          setState(() => _query = cat.label);
          fetchProducts();
        },
        child: Padding(
          padding: EdgeInsets.all(ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                cat.icon,
                color: Theme.of(context).colorScheme.primary,
                size: ResponsiveHelper.getAdaptiveIconSize(context),
              ),
              SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
              Flexible(
                child: Text(
                  cat.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
