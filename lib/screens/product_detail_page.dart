import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:living/models/product_model.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';

class ProductDetailPage extends StatefulWidget {
  final String productKey;
  const ProductDetailPage({super.key, required this.productKey});
  static const String routeName = '/product-detail';

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Product? _product;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchProduct();
  }

  Future<void> _fetchProduct() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final snapshot =
          await FirebaseDatabase.instance
              .ref('products/${widget.productKey}')
              .get();
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value;
        if (data is Map) {
          setState(() {
            _product = Product.fromJson(Map<dynamic, dynamic>.from(data));
          });
        } else {
          setState(() {
            _error = "Invalid product data format.";
          });
        }
      } else {
        setState(() {
          _error = "Product not found in database.";
        });
      }
    } catch (e) {
      setState(() {
        _error = "Failed to load product: $e";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: Loader()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Error',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
            ),
          ),
        ),
        body: Center(
          child: Text(
            _error!,
            style: TextStyle(
                              color: AppColors.error,
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
            ),
          ),
        ),
      );
    }

    if (_product == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Product not found',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
            ),
          ),
        ),
      );
    }

    final product = _product!;
    final imageSize = ResponsiveHelper.getAdaptiveImageSize(context) * 2;
    
    final cover = product.imageUrl.isNotEmpty
        ? Image.memory(
            base64Decode(product.imageUrl),
            width: imageSize,
            height: imageSize * 1.3,
            fit: BoxFit.cover,
          )
        : Container(
            width: imageSize,
            height: imageSize * 1.3,
            color: AppColors.borderLight,
            child: Icon(
              Icons.image,
              size: ResponsiveHelper.getAdaptiveIconSize(context) * 2,
            ),
          );

    return Scaffold(
      drawer: Header.buildDrawer(context),
      body: Column(
        children: [
          const Header(),
          Expanded(
            child: SingleChildScrollView(
              padding: ResponsiveHelper.getAdaptivePadding(context),
              child: Container(
                constraints: ResponsiveHelper.getFlexibleConstraints(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductHeader(product, cover),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                    _buildProductDescription(product),
                  ],
                ),
              ),
            ),
          ),
          const Footer(),
        ],
      ),
    );
  }

  Widget _buildProductHeader(Product product, Widget cover) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getAdaptiveBorderRadius(context),
        ),
      ),
      child: Padding(
        padding: ResponsiveHelper.getCardPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.5,
                  ),
                  child: cover,
                ),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 22),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                      Text(
                        'Category: ${product.category.name}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                          color: AppColors.secondaryText,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                      Row(
                        children: [
                          Text(
                            'Eco Rating: ',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                              color: AppColors.secondaryText,
                            ),
                          ),
                          Text(
                            '${product.ecoRating.toStringAsFixed(1)}★',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDescription(Product product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getAdaptiveBorderRadius(context),
        ),
      ),
      child: Padding(
        padding: ResponsiveHelper.getCardPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
            Text(
              product.description,
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 15),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
