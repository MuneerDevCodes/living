import 'package:flutter/material.dart';
import 'package:living/models/cart.dart';
import 'package:living/services/cart_dao.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:living/services/auth_helper.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/services/order_dao.dart';
import 'package:living/services/product_dao.dart';
import 'package:living/models/product_model.dart';
import 'package:living/models/order.dart';
import 'package:living/models/enums.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';
import 'dart:convert';
import 'package:living/models/user_model.dart' as app_user;
import 'package:living/services/user_dao.dart';

/// CartPage displays the user's shopping cart, using responsive and theme-driven design.
class CartPage extends StatefulWidget {
  const CartPage({super.key});
  static const String routeName = '/cart';

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartDao cartDao = CartDao();
  final OrderDao orderDao = OrderDao();
  final ScrollController _scrollController = ScrollController();
  String? _userId;
  final Map<String, Product> _productCache = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = AuthService().currentUser;
    _userId = user?.uid;
  }

  Future<Product?> _getProduct(String productId) async {
    if (_productCache.containsKey(productId)) return _productCache[productId];
    final snap = await ProductDao().getProductList().ref.child(productId).get();
    if (snap.exists && snap.value != null) {
      final product = Product.fromJson(Map<dynamic, dynamic>.from(snap.value as Map));
      _productCache[productId] = product;
      return product;
    }
    return null;
  }

  Future<void> _updateQuantity(
    String cartKey,
    Cart cart,
    String productId,
    int delta,
  ) async {
    setState(() {
      _loading = true;
    });
    final items = Map<String, CartItem>.from(cart.items);
    if (!items.containsKey(productId)) {
      setState(() {
        _loading = false;
      });
      return;
    }
    final oldItem = items[productId]!;
    final newQty = (oldItem.quantity ?? 1) + delta;
    if (newQty < 1) {
      setState(() {
        _loading = false;
      });
      return;
    }
    final product = await _getProduct(productId);
    if (product == null) {
      setState(() {
        _loading = false;
      });
      return;
    }
    items[productId] = CartItem(productId: productId, quantity: newQty);
    double total = 0.0;
    items.forEach((k, v) {
      final b = k == productId ? product : _productCache[k];
      if (b != null) total += (v.quantity ?? 1) * b.price;
    });
    final updatedCart = Cart(
      userId: cart.userId,
      items: items,
      totalAmount: total,
    );
    cartDao.updateCart(cartKey, updatedCart);
    setState(() {
      _loading = false;
    });
  }

  Future<void> _deleteItem(String cartKey, Cart cart, String productId) async {
    setState(() {
      _loading = true;
    });
    final items = Map<String, CartItem>.from(cart.items);
    items.remove(productId);
    double total = 0.0;
    for (final entry in items.entries) {
      final b = await _getProduct(entry.key);
      if (b != null) total += (entry.value.quantity ?? 1) * b.price;
    }
    final updatedCart = Cart(
      userId: cart.userId,
      items: items,
      totalAmount: total,
    );
    if (items.isEmpty) {
      cartDao.deleteCart(cartKey);
    } else {
      cartDao.updateCart(cartKey, updatedCart);
    }
    setState(() {
      _loading = false;
    });
  }

  Future<void> _orderSingleItem(
    String cartKey,
    Cart cart,
    String productId,
  ) async {
    setState(() {
      _loading = true;
    });
    final product = await _getProduct(productId);
    if (product == null) {
      setState(() {
        _loading = false;
      });
      return;
    }
    final item = cart.items[productId];
    if (item == null) {
      setState(() {
        _loading = false;
      });
      return;
    }
    final orderItems = {
      productId: OrderItem(
        productId: productId,
        quantity: item.quantity ?? 1,
        price: product.price,
        status: OrderStatus.pending,
      ),
    };
    final subtotal = (item.quantity ?? 1) * product.price;
    final shippingCost = 5.99;
    final totalAmount = subtotal + shippingCost;
    
    final order = Order(
      userId: cart.userId,
      items: orderItems,
      subtotal: subtotal,
      shippingCost: shippingCost,
      totalAmount: totalAmount,
      shippingAddress: 'Default Address', // This should be user's address
      paymentMethod: 'Default Payment', // This should be user's payment method
      status: OrderStatus.pending,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    orderDao.saveOrder(order);
    await _deleteItem(cartKey, cart, productId);
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Ordered item and removed from cart',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
          ),
        ),
      ),
    );
  }

  Future<void> _checkout(String cartKey, Cart cart) async {
    setState(() {
      _loading = true;
    });
    
    // Get user information for shipping and payment
    final user = await _getCurrentUser();
    if (user == null) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please complete your profile with shipping and payment information',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
            ),
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Check if user has shipping and payment info
    if (user.shippingInfo == null || user.paymentInfo == null) {
      setState(() {
        _loading = false;
      });
      _showProfileCompletionDialog();
      return;
    }

    // Show checkout confirmation dialog
    final confirmed = await _showCheckoutDialog(cart, user);
    if (!confirmed) {
      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      // Calculate shipping cost (simple flat rate for demo)
      const shippingCost = 5.99;
      
      await orderDao.createOrderFromCart(
        cart.userId,
        cart,
        user.shippingInfo!.formattedAddress,
        user.paymentInfo!.formattedCard,
        shippingCost,
      );
      
    setState(() {
      _loading = false;
    });
      
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
            'Order placed successfully! Order ID: ${DateTime.now().millisecondsSinceEpoch}',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
            ),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to place order: $e',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
            ),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<app_user.User?> _getCurrentUser() async {
    try {
      final snapshot = await UserDao().getUserList().orderByChild('uuid').equalTo(_userId).get();
      if (snapshot.exists && snapshot.children.isNotEmpty) {
        final snap = snapshot.children.first;
        return app_user.User.fromJson(snap.value as Map<dynamic, dynamic>);
      }
    } catch (e) {
      print('Error getting user: $e');
    }
    return null;
  }

  void _showProfileCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Complete Your Profile',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'To complete your purchase, please add your shipping address and payment information to your profile.',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
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
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Go to Profile',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showCheckoutDialog(Cart cart, app_user.User user) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Order Confirmation',
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
                'Shipping Address:',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                user.shippingInfo!.formattedAddress,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Text(
                'Payment Method:',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                user.paymentInfo!.formattedCard,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Text(
                'Order Summary:',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Subtotal: \$${cart.totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                ),
              ),
              Text(
                'Shipping: \$5.99',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                ),
              ),
              Text(
                'Total: \$${(cart.totalAmount + 5.99).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Confirm Order',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _buildCartItem(DataSnapshot snapshot) {
    final json = snapshot.value as Map<dynamic, dynamic>;
    final cart = Cart.fromJson(json);
    final cartKey = snapshot.key!;
    final items = cart.items;
    return Column(
      children: [
        // Cart Header
        Container(
          width: double.infinity,
          padding: ResponsiveHelper.getAdaptivePadding(context),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
              topRight: Radius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.shopping_cart,
                color: Colors.white,
                size: ResponsiveHelper.getAdaptiveIconSize(context) * 1.5,
              ),
              SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
              Text(
                'Shopping Cart',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              Text(
                '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                ),
              ),
            ],
          ),
        ),
        // Cart Items
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
              bottomRight: Radius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
      ),
      child: Column(
        children: [
          ...items.entries.map((entry) {
            final productId = entry.key;
            final item = entry.value;
            return FutureBuilder<Product?>(
              future: _getProduct(productId),
              builder: (context, snap) {
                if (!snap.hasData) {
                      return Container(
                        padding: ResponsiveHelper.getAdaptivePadding(context),
                        child: Row(
                          children: [
                            Container(
                              width: ResponsiveHelper.getAdaptiveImageSize(context),
                              height: ResponsiveHelper.getAdaptiveImageSize(context) * 1.5,
                              decoration: BoxDecoration(
                                color: AppColors.borderLight,
                                borderRadius: BorderRadius.circular(
                                  ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.4,
                                ),
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                ),
                              ),
                            ),
                            SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 120,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: AppColors.borderLight,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                                  Container(
                                    width: 80,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: AppColors.borderLight,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                    ),
                  );
                }
                final product = snap.data!;
                final imageSize = ResponsiveHelper.getAdaptiveImageSize(context);
                
                Widget leadingWidget;
                if (product.imageUrl.isNotEmpty) {
                  try {
                    leadingWidget = ClipRRect(
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
                        leadingWidget = Container(
                          width: imageSize,
                          height: imageSize * 1.5,
                          decoration: BoxDecoration(
                            color: AppColors.borderLight,
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.4,
                            ),
                          ),
                          child: Icon(
                            Icons.shopping_bag,
                            size: ResponsiveHelper.getAdaptiveIconSize(context) * 1.5,
                      color: AppColors.mutedText,
                          ),
                    );
                  }
                } else {
                      leadingWidget = Container(
                        width: imageSize,
                        height: imageSize * 1.5,
                        decoration: BoxDecoration(
                          color: AppColors.borderLight,
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.4,
                          ),
                        ),
                        child: Icon(
                          Icons.shopping_bag,
                          size: ResponsiveHelper.getAdaptiveIconSize(context) * 1.5,
                    color: AppColors.mutedText,
                        ),
                      );
                    }
                    
                    return Container(
                      margin: EdgeInsets.only(
                        left: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5,
                        right: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5,
                        top: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3,
                      ),
                      padding: ResponsiveHelper.getAdaptivePadding(context),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.6,
                        ),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              leadingWidget,
                              SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                    product.name,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryText,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                                    Text(
                                      'Category: ${product.category.name}',
                                      style: TextStyle(
                                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          size: ResponsiveHelper.getAdaptiveIconSize(context) * 0.8,
                                          color: Colors.amber[600],
                                        ),
                                        SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                                        Text(
                                          '${product.ecoRating.toStringAsFixed(1)}',
                    style: TextStyle(
                                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                      color: AppColors.secondaryText,
                    ),
                  ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$${product.price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                                  Text(
                                    'Total: \$${(product.price * (item.quantity ?? 1)).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Quantity Controls
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(
                                    ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.4,
                                  ),
                                  border: Border.all(color: AppColors.borderLight),
                                ),
                                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.remove,
                                        size: ResponsiveHelper.getAdaptiveIconSize(context) * 0.8,
                          color: AppColors.error,
                        ),
                        onPressed: () => _updateQuantity(cartKey, cart, productId, -1),
                                      constraints: BoxConstraints(
                                        minWidth: ResponsiveHelper.getAdaptiveIconSize(context) * 2,
                                        minHeight: ResponsiveHelper.getAdaptiveIconSize(context) * 2,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5,
                                      ),
                                      child: Text(
                        '${item.quantity ?? 1}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryText,
                                        ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.add,
                                        size: ResponsiveHelper.getAdaptiveIconSize(context) * 0.8,
                          color: AppColors.success,
                        ),
                        onPressed: () => _updateQuantity(cartKey, cart, productId, 1),
                                      constraints: BoxConstraints(
                                        minWidth: ResponsiveHelper.getAdaptiveIconSize(context) * 2,
                                        minHeight: ResponsiveHelper.getAdaptiveIconSize(context) * 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Action Buttons
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(
                                        ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.4,
                                      ),
                                    ),
                                    child: IconButton(
                        icon: Icon(
                                        Icons.delete_outline,
                          color: AppColors.error,
                          size: ResponsiveHelper.getAdaptiveIconSize(context),
                        ),
                        onPressed: () => _deleteItem(cartKey, cart, productId),
                                      tooltip: 'Remove from cart',
                                    ),
                                  ),
                                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(
                                        ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.4,
                                      ),
                                    ),
                                    child: IconButton(
                        icon: Icon(
                                        Icons.shopping_bag_outlined,
                          color: AppColors.success,
                          size: ResponsiveHelper.getAdaptiveIconSize(context),
                        ),
                                      tooltip: 'Buy now',
                        onPressed: () => _orderSingleItem(cartKey, cart, productId),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                      ),
                    ],
                  ),
                );
              },
            );
          }),
            ],
          ),
        ),
        // Cart Summary
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
        Container(
            padding: ResponsiveHelper.getAdaptivePadding(context),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal:',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                      color: AppColors.secondaryText,
                    ),
                  ),
                  Text(
                    '\$${cart.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Shipping:',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                      color: AppColors.secondaryText,
                    ),
                  ),
                  Text(
                    '\$5.99',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Divider(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                  Text(
                    '\$${(cart.totalAmount + 5.99).toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                    fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
                ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _checkout(cartKey, cart),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.6,
                      ),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_checkout,
                        size: ResponsiveHelper.getAdaptiveIconSize(context),
                      ),
                      SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                      Text(
                        'Proceed to Checkout',
                    style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
    );
  }

  /// Build method for the cart page, using only ResponsiveHelper and AppTheme/AppColors.
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
                if (_loading) const Positioned.fill(child: Loader()),
                StreamBuilder(
                  stream:
                      cartDao
                          .getCartList()
                          .orderByChild('userId')
                          .equalTo(_userId)
                          .onValue,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Loader();
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Container(
                          padding: ResponsiveHelper.getAdaptivePadding(context),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: ResponsiveHelper.getAdaptiveImageSize(context) * 2,
                                height: ResponsiveHelper.getAdaptiveImageSize(context) * 2,
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.error_outline,
                                  size: ResponsiveHelper.getAdaptiveIconSize(context) * 3,
                                  color: AppColors.error,
                                ),
                              ),
                              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                              Text(
                                'Oops! Something went wrong',
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                              Text(
                                'Unable to load your cart. Please try again.',
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                                  color: AppColors.secondaryText,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {});
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: ResponsiveHelper.getAdaptivePadding(context),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.6,
                                    ),
                                  ),
                                ),
                                icon: Icon(
                                  Icons.refresh,
                                  size: ResponsiveHelper.getAdaptiveIconSize(context),
                                ),
                                label: Text(
                                  'Try Again',
                          style: TextStyle(
                                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    final data = snapshot.data?.snapshot.value;
                    if (data == null) {
                      return Center(
                        child: Container(
                          padding: ResponsiveHelper.getAdaptivePadding(context),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: ResponsiveHelper.getAdaptiveImageSize(context) * 2,
                                height: ResponsiveHelper.getAdaptiveImageSize(context) * 2,
                                decoration: BoxDecoration(
                                  color: AppColors.borderLight,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.shopping_cart_outlined,
                                  size: ResponsiveHelper.getAdaptiveIconSize(context) * 3,
                                  color: AppColors.mutedText,
                                ),
                              ),
                              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                              Text(
                                'Your cart is empty',
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 20),
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                              Text(
                                'Start shopping to add items to your cart',
                          style: TextStyle(
                                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                            color: AppColors.secondaryText,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: ResponsiveHelper.getAdaptivePadding(context),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.6,
                                    ),
                                  ),
                                ),
                                icon: Icon(
                                  Icons.shopping_bag,
                                  size: ResponsiveHelper.getAdaptiveIconSize(context),
                                ),
                                label: Text(
                                  'Start Shopping',
                                  style: TextStyle(
                                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    final carts = <MapEntry<String, dynamic>>[];
                    final map = Map<String, dynamic>.from(data as dynamic);
                    map.forEach((key, value) {
                      carts.add(MapEntry(key, value));
                    });
                    return ListView.builder(
                      controller: _scrollController,
                      padding: ResponsiveHelper.getAdaptivePadding(context),
                      itemCount: carts.length,
                      itemBuilder: (context, index) {
                        final entry = carts[index];
                        final snapshot = DataSnapshotFake(
                          entry.key,
                          entry.value,
                        );
                        return _buildCartItem(snapshot);
                      },
                    );
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

// Helper class to fake DataSnapshot for compatibility with _buildCartItem
class DataSnapshotFake implements DataSnapshot {
  @override
  final String? key;
  @override
  final dynamic value;
  DataSnapshotFake(this.key, this.value);

  @override
  bool get exists => value != null;
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
