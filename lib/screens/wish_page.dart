import 'dart:convert';

import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:living/models/wish.dart';
import 'package:living/services/wish_dao.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:living/models/product_model.dart';
import 'package:living/services/product_dao.dart';
import 'package:living/services/cart_dao.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';

class WishPage extends StatefulWidget {
  const WishPage({super.key});
  static const String routeName = '/wishlist';

  @override
  State<WishPage> createState() => _WishPageState();
}

class _WishPageState extends State<WishPage> {
  final WishDao wishDao = WishDao();
  final ScrollController _scrollController = ScrollController();
  String? _userId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid;
  }

  Widget _buildProductTile(String productId) {
    return FutureBuilder<DataSnapshot>(
      future: ProductDao().getProductList().ref.child(productId).get(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Loader();
        }
        if (snap.hasError) return const Text('Error loading product');
        if (!snap.hasData || !snap.data!.exists) {
          return ListTile(
            leading: Icon(
              Icons.favorite, 
              color: AppColors.mutedText,
              size: ResponsiveHelper.getAdaptiveIconSize(context),
            ),
            title: Text(
              'product not found ($productId)',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
          );
        }
        final productJson = snap.data!.value as Map<dynamic, dynamic>;
        final product = Product.fromJson(productJson);
        Widget leading;
        if (product.imageUrl.isNotEmpty) {
          try {
            final imageSize = ResponsiveHelper.getAdaptiveImageSize(context);
            leading = ClipRRect(
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.4,
              ),
              child: Image.memory(
                base64Decode(product.imageUrl),
                width: imageSize,
                height: imageSize * 1.5,
                fit: BoxFit.cover,
              ),
            );
          } catch (_) {
            leading = Icon(
              Icons.favorite, 
              color: AppColors.mutedText,
              size: ResponsiveHelper.getAdaptiveIconSize(context),
            );
          }
        } else {
          leading = Icon(
            Icons.favorite, 
            color: AppColors.mutedText,
            size: ResponsiveHelper.getAdaptiveIconSize(context),
          );
        }
        return Card(
                              color: AppColors.success.withValues(alpha: 0.1),
          margin: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5,
            vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3,
          ),
          child: ListTile(
            leading: leading,
            title: Text(
              product.name,
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              product.description,
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                color: AppColors.secondaryText,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.price.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                IconButton(
                  icon: Icon(
                    Icons.shopping_cart,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                    color: AppColors.info,
                  ),
                  tooltip: 'Add to Cart',
                  onPressed:
                      _userId == null
                          ? null
                          : () async {
                            setState(() {
                              _loading = true;
                            });
                            await CartDao().addToCart(
                              _userId!,
                              product,
                              1,
                              productId,
                            );
                            setState(() {
                              _loading = false;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Added to cart',
                                    style: TextStyle(
                                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete, 
                    color: AppColors.error,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                  ),
                  tooltip: 'Remove from Wishlist',
                  onPressed:
                      _userId == null
                          ? null
                          : () async {
                            setState(() {
                              _loading = true;
                            });
                            await wishDao.removeFromWishList(_userId!, productId);
                            setState(() {
                              _loading = false;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Removed from wishlist',
                                    style: TextStyle(
                                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWishListProducts(DataSnapshot snapshot) {
    final json = snapshot.value as Map<dynamic, dynamic>;
    final wishList = WishList.fromJson(json);
    final productIds = wishList.items.values.map((wish) => wish.productId).toList();

    if (productIds.isEmpty) {
      return Center(
        child: Text(
          'No products in wishlist.',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
            color: AppColors.secondaryText,
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: productIds.length,
      itemBuilder: (context, i) => _buildProductTile(productIds[i]),
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
                if (_loading) const Positioned.fill(child: Loader()),
                FirebaseAnimatedList(
                  controller: _scrollController,
                  query: wishDao
                      .getWishList()
                      .orderByChild('userId')
                      .equalTo(_userId),
                  itemBuilder: (context, snapshot, animation, index) {
                    return _buildWishListProducts(snapshot);
                  },
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
