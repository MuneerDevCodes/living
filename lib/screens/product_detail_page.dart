import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:living/models/product_model.dart';
import 'package:living/services/product_dao.dart';
import 'package:living/services/cart_dao.dart';
import 'package:living/services/wish_dao.dart';
import 'package:living/services/auth_helper.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';

/// ProductDetailPage displays details for a specific product, using responsive and theme-driven design.
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
  final _reviewCtrl = TextEditingController();
  int _rating = 0;
  bool _loading = false;
  int _quantity = 1;

  User? get _user => AuthService().currentUser;

  @override
  void initState() {
    super.initState();
    _fetchProduct();
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
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

  Future<void> _submitReview() async {
    if (_product == null) return;
    if (_rating == 0 || _reviewCtrl.text.trim().isEmpty) {
      setState(() => _error = "Please provide a rating and comment.");
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userId = _user!.uid;
      final review = Review(
        userId: userId,
        rating: _rating,
        comment: _reviewCtrl.text.trim(),
        likes: 0,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      final updatedReviews = Map<String, Review>.from(_product!.reviews);
      updatedReviews[userId] = review;
      final allRatings = updatedReviews.values.map((r) => r.rating).toList();
      final avg =
          allRatings.isEmpty
              ? 0.0
              : allRatings.reduce((a, b) => a + b) / allRatings.length;
      final updatedProduct = Product(
        name: _product!.name,
        category: _product!.category,
        description: _product!.description,
        ecoRating: _product!.ecoRating,
        imageUrl: _product!.imageUrl,
        price: _product!.price,
        ratings: Ratings(average: avg, count: allRatings.length),
        reviews: updatedReviews,
      );
      ProductDao().updateProduct(widget.productKey, updatedProduct);
      setState(() {
        _product = updatedProduct;
        _reviewCtrl.clear();
        _rating = 0;
      });
    } catch (e) {
      setState(() => _error = "Failed to submit review: $e");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  /// Build method for the product detail page, using only ResponsiveHelper and AppTheme/AppColors.
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
              color: AppColors.error,
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
      return const Scaffold(body: Center(child: Text('Product not found')));
    }

    final product = _product!;
    final cover =
        product.imageUrl.isNotEmpty
            ? Image.memory(
              base64Decode(product.imageUrl),
              width: ResponsiveHelper.getAdaptiveImageSize(context),
              height: ResponsiveHelper.getAdaptiveImageSize(context) * 1.33,
              fit: BoxFit.cover,
            )
            : Container(
              width: ResponsiveHelper.getAdaptiveImageSize(context),
              height: ResponsiveHelper.getAdaptiveImageSize(context) * 1.33,
              color: AppColors.borderLight,
              child: Icon(
                Icons.shopping_bag,
                size: ResponsiveHelper.getAdaptiveIconSize(context),
                color: AppColors.mutedText,
              ),
            );
    final reviews =
        product.reviews.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final canReview = _user != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: Header.buildDrawer(context),
      body: Column(
        children: [
          const Header(),
          Expanded(
            child: SingleChildScrollView(
              padding: ResponsiveHelper.getAdaptivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      cover,
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
                                color: AppColors.primaryText,
                              ),
                            ),
                            Text(
                              'Category: ${product.category.name}',
                              style: TextStyle(fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16), color: AppColors.secondaryText),
                            ),
                            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                            Text('Price: \$${product.price.toStringAsFixed(2)}', style: TextStyle(color: AppColors.primary)),
                            Text('Eco Rating: ${product.ecoRating.toStringAsFixed(1)} ★', style: TextStyle(color: AppColors.success)),
                            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.amber[700],
                                  size: ResponsiveHelper.getAdaptiveIconSize(context),
                                ),
                                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                                Text(
                                  '${product.ratings.average.toStringAsFixed(1)} (${product.ratings.count} reviews)',
                                  style: TextStyle(color: AppColors.secondaryText),
                                ),
                              ],
                            ),
                            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                            Row(
                              children: [
                                Text(
                                  'Quantity:',
                                  style: TextStyle(
                                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
                                IconButton(
                                  icon: Icon(
                                    Icons.remove_circle_outline,
                                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                                    color: _quantity > 1 ? AppColors.primary : AppColors.mutedText,
                                  ),
                                  onPressed: _quantity > 1 ? () {
                                    setState(() {
                                      _quantity--;
                                    });
                                  } : null,
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5,
                                  ),
                                  child: Text(
                                    '$_quantity',
                                    style: TextStyle(
                                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.add_circle_outline,
                                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                                    color: AppColors.primary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _quantity++;
                                    });
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _user == null ? null : () async {
                                      setState(() {
                                        _loading = true;
                                      });
                                      try {
                                            final userId = _user!.uid;
                                            await CartDao().addToCart(
                                              userId,
                                              product,
                                          _quantity,
                                              widget.productKey,
                                            );
                                            if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                'Added $_quantity ${_quantity == 1 ? 'item' : 'items'} to cart',
                                                style: TextStyle(
                                                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                                                ),
                                              ),
                                              backgroundColor: AppColors.success,
                                              action: SnackBarAction(
                                                label: 'View Cart',
                                                textColor: Colors.white,
                                                onPressed: () {
                                                  Navigator.pushNamed(context, '/cart');
                                                },
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed to add to cart: $e',
                                                style: TextStyle(
                                                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                                                ),
                                              ),
                                              backgroundColor: AppColors.error,
                                            ),
                                          );
                                        }
                                      } finally {
                                        setState(() {
                                          _loading = false;
                                        });
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: ResponsiveHelper.getAdaptivePadding(context),
                                    ),
                                    icon: _loading 
                                      ? SizedBox(
                                          width: ResponsiveHelper.getAdaptiveIconSize(context),
                                          height: ResponsiveHelper.getAdaptiveIconSize(context),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Icon(
                                          Icons.shopping_cart,
                                          size: ResponsiveHelper.getAdaptiveIconSize(context),
                                        ),
                                    label: Text(
                                      _loading ? 'Adding...' : 'Add to Cart',
                                      style: TextStyle(
                                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
                                IconButton(
                                  icon: Icon(
                                    Icons.favorite_border,
                                    size: ResponsiveHelper.getAdaptiveIconSize(context) * 1.2,
                                    color: AppColors.error,
                                  ),
                                  onPressed: _user == null ? null : () async {
                                    try {
                                            final userId = _user!.uid;
                                            await WishDao().addToWishList(
                                              userId,
                                              product,
                                              widget.productKey,
                                            );
                                            if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Added to wishlist',
                                              style: TextStyle(
                                                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                                              ),
                                            ),
                                            backgroundColor: AppColors.success,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to add to wishlist: $e',
                                              style: TextStyle(
                                                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                                              ),
                                            ),
                                            backgroundColor: AppColors.error,
                                                ),
                                              );
                                            }
                                    }
                                  },
                                  tooltip: 'Add to Wishlist',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                  Text(product.description, style: TextStyle(fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 15))),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                  Divider(),
                  Text(
                    'Reviews',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                  if (reviews.isEmpty)
                    Text(
                      'No reviews yet.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ...reviews.map(
                    (r) => Card(
                      margin: EdgeInsets.symmetric(vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            r.userId.isNotEmpty
                                ? r.userId[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Row(
                          children: [
                            ...List.generate(
                              5,
                              (i) => Icon(
                                i < r.rating ? Icons.star : Icons.star_border,
                                color: Colors.amber[700],
                                size: ResponsiveHelper.getAdaptiveIconSize(context),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.comment),
                            if (_user != null && r.userId == _user!.uid)
                              Row(
                                children: [
                                  TextButton(
                                    onPressed:
                                        _loading
                                            ? null
                                            : () {
                                              _reviewCtrl.text = r.comment;
                                              setState(() {
                                                _rating = r.rating;
                                              });
                                            },
                                    child: Text(
                                      'Edit',
                                      style: TextStyle(fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12)),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed:
                                        _loading
                                            ? null
                                            : () async {
                                              final updatedReviews =
                                                  Map<String, Review>.from(
                                                    _product!.reviews,
                                                  );
                                              updatedReviews.remove(_user!.uid);
                                              final allRatings =
                                                  updatedReviews.values
                                                      .map((r) => r.rating)
                                                      .toList();
                                              final avg =
                                                  allRatings.isEmpty
                                                      ? 0.0
                                                      : allRatings.reduce(
                                                            (a, b) => a + b,
                                                          ) /
                                                          (allRatings.isEmpty
                                                              ? 1
                                                              : allRatings
                                                                  .length);
                                              final updatedProduct = Product(
                                                name: _product!.name,
                                                category: _product!.category,
                                                description: _product!.description,
                                                ecoRating: _product!.ecoRating,
                                                imageUrl: _product!.imageUrl,
                                                price: _product!.price,
                                                ratings: Ratings(
                                                  average: avg,
                                                  count: allRatings.length,
                                                ),
                                                reviews: updatedReviews,
                                              );
                                              ProductDao().updateProduct(
                                                widget.productKey,
                                                updatedProduct,
                                              );
                                              setState(() {
                                                _product = updatedProduct;
                                                _reviewCtrl.clear();
                                                _rating = 0;
                                              });
                                            },
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(
                                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        trailing: Text(
                          DateTime.fromMillisecondsSinceEpoch(
                            r.createdAt,
                          ).toLocal().toString().split(' ')[0],
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 11),
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                  if (canReview) ...[
                    Divider(),
                    Text(
                      'Add Your Review',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => IconButton(
                            icon: Icon(
                              i < _rating ? Icons.star : Icons.star_border,
                              color: Colors.amber[700],
                            ),
                            onPressed:
                                _loading
                                    ? null
                                    : () => setState(() => _rating = i + 1),
                          ),
                        ),
                      ],
                    ),
                    TextField(
                      controller: _reviewCtrl,
                      decoration: InputDecoration(
                        labelText: 'Your review',
                        border: OutlineInputBorder(),
                      ),
                      minLines: 2,
                      maxLines: 4,
                      enabled: !_loading,
                    ),
                    if (_error != null)
                      Padding(
                        padding: EdgeInsets.only(top: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                        child: Text(
                          _error!,
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                    ElevatedButton(
                      onPressed: _loading ? null : _submitReview,
                      child:
                          _loading
                              ? SizedBox(
                                width: ResponsiveHelper.getAdaptiveSpacing(context) * 1.2,
                                height: ResponsiveHelper.getAdaptiveSpacing(context) * 1.2,
                                child: Loader(),
                              )
                              : Text('Submit Review'),
                    ),
                  ] else ...[
                    Divider(),
                    Text(
                      'Login to add your review.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Footer(),
        ],
      ),
    );
  }
}
