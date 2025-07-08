import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:living/models/product_model.dart';
import 'package:living/services/product_dao.dart';
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
  final ScrollController _scrollController = ScrollController();

  void _showProductModal({Product? product, String? key}) {
    showDialog(
      context: context,
      builder: (ctx) => ProductModal(
        product: product,
        onSubmit: (newProduct) {
          if (key != null) {
            productDao.updateProduct(key, newProduct);
          } else {
            productDao.saveProduct(newProduct);
          }
          setState(() {});
        },
      ),
    );
  }

  void _deleteProduct(String key) {
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
        trailing: Row(
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
        ),
      ),
    );
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
                StreamBuilder(
                  stream: productDao.getProductList().onValue,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Positioned.fill(child: Loader());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading products',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                          ),
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
