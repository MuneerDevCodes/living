import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:living/models/product_model.dart';
import 'package:living/services/product_dao.dart';
import 'package:living/services/admin_service.dart';
import 'package:living/widgets/product_modal.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/screens/product_detail_page.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';
import 'dart:convert';

class ManageProductPage extends StatefulWidget {
  const ManageProductPage({super.key});
  static const routeName = "/manage-products";

  @override
  State<ManageProductPage> createState() => _ManageProductPageState();
}

class _ManageProductPageState extends State<ManageProductPage> {
  final ProductDao productDao = ProductDao();
  final AdminService adminService = AdminService();
  final ScrollController _scrollController = ScrollController();
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _testConnection();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await adminService.isAdmin();
    setState(() {
      _isAdmin = isAdmin;
      _isLoading = false;
    });
  }

  Future<void> _testConnection() async {
    try {
      await productDao.testConnection();
    } catch (e) {
      print('Connection test failed in initState: $e');
    }
  }

  void _showProductModal({Product? product, String? key}) {
    if (!_isAdmin) return;
    
    showDialog(
      context: context,
      builder: (ctx) => ProductModal(
        product: product,
        onSubmit: (newProduct) async {
          try {
            if (key != null) {
              // Preserve existing reviews and ratings when editing
              final existingProduct = await productDao.getProductById(key);
              if (existingProduct != null) {
                final updatedProduct = Product(
                  name: newProduct.name,
                  category: newProduct.category,
                  description: newProduct.description,
                  price: newProduct.price,
                  ecoRating: newProduct.ecoRating,
                  imageUrl: newProduct.imageUrl,
                  ratings: existingProduct.ratings,
                  reviews: existingProduct.reviews,
                );
                await productDao.updateProduct(key, updatedProduct);
              } else {
                await productDao.updateProduct(key, newProduct);
              }
            } else {
              await productDao.saveProduct(newProduct);
            }
            setState(() {});
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error saving product: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _deleteProduct(String key) {
    if (!_isAdmin) return;
    
    productDao.deleteProduct(key);
    setState(() {});
  }

  Widget _buildProductItem(DataSnapshot snapshot) {
    final json = snapshot.value as Map<dynamic, dynamic>;
    final product = Product.fromJson(json);
    final imageSize = ResponsiveHelper.getAdaptiveImageSize(context);

    // Use imageUrl for product image
    Widget imageWidget;
    if (product.imageUrl.isNotEmpty) {
      try {
        imageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.4,
          ),
          child: Image.memory(
            base64Decode(product.imageUrl),
            width: imageSize,
            height: imageSize * 1.3,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {
        imageWidget = Icon(
          Icons.image,
          size: ResponsiveHelper.getAdaptiveIconSize(context) * 2,
          color: AppColors.mutedText,
        );
      }
    } else {
      imageWidget = Icon(
        Icons.image,
        size: ResponsiveHelper.getAdaptiveIconSize(context) * 2,
        color: AppColors.mutedText,
      );
    }

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5,
        vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getAdaptiveBorderRadius(context),
        ),
      ),
      child: ListTile(
        leading: imageWidget,
        title: Text(
          product.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.category.name,
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
            Text(
              'Eco Rating: ${product.ecoRating.toStringAsFixed(1)}★',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(productKey: snapshot.key!),
            ),
          );
        },
        trailing: _isAdmin ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.edit,
                color: AppColors.info,
                size: ResponsiveHelper.getAdaptiveIconSize(context),
              ),
              onPressed: () => _showProductModal(product: product, key: snapshot.key),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: Icon(
                Icons.delete,
                color: AppColors.error,
                size: ResponsiveHelper.getAdaptiveIconSize(context),
              ),
              onPressed: () => _deleteProduct(snapshot.key!),
              tooltip: 'Delete',
            ),
          ],
        ) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: Loader()),
      );
    }

    return Scaffold(
      drawer: Header.buildDrawer(context),
      body: Column(
        children: [
          const Header(),
          Expanded(
            child: Stack(
              children: [
                StreamBuilder(
                  stream: productDao.getProductList().onValue,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Positioned.fill(child: Loader());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Error loading products',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              '${snapshot.error}',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                                color: Colors.red,
                              ),
                            ),
                            SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {});
                              },
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }
                    final data = snapshot.data?.snapshot.value;
                    if (data == null) {
                      return Center(
                        child: Text(
                          'No products found.',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                          ),
                        ),
                      );
                    }
                    final products = <MapEntry<String, dynamic>>[];
                    final map = Map<String, dynamic>.from(data as dynamic);
                    map.forEach((key, value) {
                      products.add(MapEntry(key, value));
                    });
                    return ListView.builder(
                      controller: _scrollController,
                      padding: ResponsiveHelper.getAdaptivePadding(context),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final entry = products[index];
                        final snapshot = DataSnapshotFake(
                          entry.key,
                          entry.value,
                        );
                        return _buildProductItem(snapshot);
                      },
                    );
                  },
                ),
                // Only show floating action button for admin users
                if (_isAdmin)
                  Positioned(
                    bottom: ResponsiveHelper.getAdaptiveSpacing(context),
                    right: ResponsiveHelper.getAdaptiveSpacing(context),
                    child: FloatingActionButton(
                      onPressed: () => _showProductModal(),
                      tooltip: 'Add Product',
                      child: Icon(
                        Icons.add,
                        size: ResponsiveHelper.getAdaptiveIconSize(context),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Footer(),
        ],
      ),
    );
  }
}

// Helper class to fake DataSnapshot for compatibility with _buildProductItem
class DataSnapshotFake implements DataSnapshot {
  @override
  final String? key;
  @override
  final dynamic value;
  DataSnapshotFake(this.key, this.value);

  // ...implement only the members used by _buildProductItem...
  @override
  bool get exists => value != null;
  // The rest can throw UnimplementedError if not used
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
