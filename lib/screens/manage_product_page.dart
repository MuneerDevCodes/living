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
  
  // Multi-selection state
  bool _isSelectionMode = false;
  final Set<String> _selectedProducts = <String>{};
  bool _isSelectAll = false;

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

  // Multi-selection methods
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedProducts.clear();
        _isSelectAll = false;
      }
    });
  }

  void _toggleProductSelection(String productKey) {
    setState(() {
      if (_selectedProducts.contains(productKey)) {
        _selectedProducts.remove(productKey);
      } else {
        _selectedProducts.add(productKey);
      }
      _updateSelectAllState();
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_isSelectAll) {
        _selectedProducts.clear();
        _isSelectAll = false;
      } else {
        // Get all product keys from the current stream data
        // This will be handled in the StreamBuilder
        _isSelectAll = true;
      }
    });
  }

  void _updateSelectAllState() {
    // This will be called when individual selections change
    // The actual logic will be in the StreamBuilder
  }

  Future<void> _bulkDelete() async {
    if (_selectedProducts.isEmpty) return;

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Selected Products'),
          content: Text(
            'Are you sure you want to delete ${_selectedProducts.length} selected product${_selectedProducts.length == 1 ? '' : 's'}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete All'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Delete all selected products
        for (final productKey in _selectedProducts) {
          await productDao.deleteProduct(productKey);
        }
        
        // Exit selection mode
        setState(() {
          _isSelectionMode = false;
          _selectedProducts.clear();
          _isSelectAll = false;
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting products: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  Future<void> _deleteProduct(String key) async {
    if (!_isAdmin) return;
    
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Product'),
          content: const Text('Are you sure you want to delete this product? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      
      if (confirmed == true) {
        await productDao.deleteProduct(key);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSelectionHeader() {
    if (!_isSelectionMode) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Select all checkbox
          Row(
            children: [
              Checkbox(
                value: _isSelectAll,
                onChanged: (value) => _toggleSelectAll(),
                activeColor: Theme.of(context).colorScheme.primary,
              ),
              Text(
                'Select All',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Selection count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_selectedProducts.length} selected',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Bulk delete button
          if (_selectedProducts.isNotEmpty)
            ElevatedButton.icon(
              onPressed: _bulkDelete,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.delete, size: 18),
              label: const Text('Delete'),
            ),
          const SizedBox(width: 8),
          // Exit selection mode button
          IconButton(
            onPressed: _toggleSelectionMode,
            icon: const Icon(Icons.close),
            tooltip: 'Exit Selection Mode',
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(DataSnapshot snapshot) {
    final json = snapshot.value as Map<dynamic, dynamic>;
    final product = Product.fromJson(json);
    final productKey = snapshot.key!;
    final imageSize = ResponsiveHelper.getAdaptiveImageSize(context);
    final isSelected = _selectedProducts.contains(productKey);

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
        side: isSelected ? BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ) : BorderSide.none,
      ),
      elevation: isSelected ? 4 : 1,
      child: Stack(
        children: [
          ListTile(
            leading: Stack(
              children: [
                imageWidget,
                if (_isSelectionMode)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? Theme.of(context).colorScheme.primary 
                          : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSelected ? Icons.check : Icons.radio_button_unchecked,
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              product.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                color: isSelected ? Theme.of(context).colorScheme.primary : null,
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
            onTap: _isSelectionMode 
              ? () => _toggleProductSelection(productKey)
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailPage(productKey: productKey),
                    ),
                  );
                },
            trailing: _isSelectionMode 
              ? null 
              : (_isAdmin ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: AppColors.info,
                        size: ResponsiveHelper.getAdaptiveIconSize(context),
                      ),
                      onPressed: () => _showProductModal(product: product, key: productKey),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: AppColors.error,
                        size: ResponsiveHelper.getAdaptiveIconSize(context),
                      ),
                      onPressed: () async => await _deleteProduct(productKey),
                      tooltip: 'Delete',
                    ),
                  ],
                ) : null),
          ),
          if (_isSelectionMode)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected 
                    ? Theme.of(context).colorScheme.primary 
                    : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected 
                      ? Theme.of(context).colorScheme.primary 
                      : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isSelected 
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
              ),
            ),
        ],
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
          // Selection header
          _buildSelectionHeader(),
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
                            const SizedBox(height: 10),
                            Text(
                              '${snapshot.error}',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {});
                              },
                              child: const Text('Retry'),
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

                    // Update select all state based on current products
                    if (_isSelectionMode && products.isNotEmpty) {
                      final allProductKeys = products.map((e) => e.key).toSet();
                      if (_isSelectAll && _selectedProducts.length != allProductKeys.length) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() {
                            _selectedProducts.addAll(allProductKeys);
                          });
                        });
                      } else if (!_isSelectAll && _selectedProducts.length == allProductKeys.length) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() {
                            _isSelectAll = true;
                          });
                        });
                      }
                    }

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
                // Floating action buttons
                Positioned(
                  bottom: ResponsiveHelper.getAdaptiveSpacing(context),
                  right: ResponsiveHelper.getAdaptiveSpacing(context),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Selection mode toggle button
                      if (_isAdmin)
                        FloatingActionButton(
                          onPressed: _toggleSelectionMode,
                          tooltip: _isSelectionMode ? 'Exit Selection Mode' : 'Enter Selection Mode',
                          backgroundColor: _isSelectionMode 
                            ? Colors.orange 
                            : Theme.of(context).colorScheme.secondary,
                          child: Icon(
                            _isSelectionMode ? Icons.close : Icons.select_all,
                            size: ResponsiveHelper.getAdaptiveIconSize(context),
                          ),
                        ),
                      const SizedBox(height: 12),
                      // Add product button
                      if (_isAdmin && !_isSelectionMode)
                        FloatingActionButton(
                          onPressed: () => _showProductModal(),
                          tooltip: 'Add Product',
                          child: Icon(
                            Icons.add,
                            size: ResponsiveHelper.getAdaptiveIconSize(context),
                          ),
                        ),
                    ],
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
