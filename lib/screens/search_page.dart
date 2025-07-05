import 'package:flutter/material.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/services/product_dao.dart';
import 'package:living/models/product_model.dart';
import 'dart:convert';
import 'package:living/widgets/loader.dart';
import 'package:living/screens/product_detail_page.dart';
import 'package:living/services/category_constants.dart';

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
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      padding: const EdgeInsets.all(20),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Search Products',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _controller,
                                decoration: InputDecoration(
                                  hintText:
                                      'Enter product name, category, or keyword',
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  isDense: true,
                                  suffixIcon:
                                      _query.isNotEmpty
                                          ? IconButton(
                                            icon: const Icon(Icons.clear),
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
                              ),
                              const SizedBox(height: 12),
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

  Widget _buildProductList() {
    if (_query.isEmpty) return _buildCategories(context);

    final filtered = _applySearchAndSort(_products);
    if (filtered.isEmpty) {
      return FutureBuilder(
        future: Future.delayed(const Duration(milliseconds: 300)),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(); // Don't show anything yet
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'No results found.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 18),
              _buildCategories(context),
            ],
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Sort by:'),
            const SizedBox(width: 10),
            DropdownButton<String>(
              value: _selectedSort,
              items:
                  _sortOptions
                      .map(
                        (opt) => DropdownMenuItem(value: opt, child: Text(opt)),
                      )
                      .toList(),
              onChanged: (val) {
                if (val != null && val != _selectedSort) {
                  setState(() => _selectedSort = val);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 18),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          separatorBuilder: (context, i) => const Divider(),
          itemBuilder: (context, i) {
            final entry = filtered[i];
            final product = entry.value;
            final key = entry.key;

            Widget leadingWidget;
            if (product.imageUrl.isNotEmpty) {
              try {
                final imageBytes = base64Decode(product.imageUrl);
                leadingWidget = ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    imageBytes,
                    width: 40,
                    height: 60,
                    fit: BoxFit.fill,
                  ),
                );
              } catch (_) {
                leadingWidget = _placeholderImage();
              }
            } else {
              leadingWidget = _placeholderImage();
            }

            return ListTile(
              leading: leadingWidget,
              title: Text(product.name),
              subtitle: Text(product.category.name),
              trailing: Text('${product.ecoRating.toStringAsFixed(1)}★'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailPage(productKey: key),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 18),
        _buildCategories(context),
      ],
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: Colors.grey[300],
      width: 40,
      height: 60,
      child: const Icon(Icons.image, color: Colors.white70, size: 32),
    );
  }

  Widget _buildCategories(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
            child: Text(
              'Explore Categories',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.8,
          ),
          itemBuilder: (context, i) {
            final cat = _categories[i];
            return Material(
              color: Theme.of(
                context,
              ).colorScheme.secondary.withAlpha((0.08 * 255).toInt()),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  _controller.text = cat.label;
                  setState(() => _query = cat.label);
                  fetchProducts();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      cat.icon,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cat.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
