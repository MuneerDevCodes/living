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
    final order = Order(
      userId: cart.userId,
      items: orderItems,
      totalAmount: (item.quantity ?? 1) * product.price,
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
    final orderItems = <String, OrderItem>{};
    for (final entry in cart.items.entries) {
      final product = await _getProduct(entry.key);
      if (product != null) {
        orderItems[entry.key] = OrderItem(
          productId: entry.key,
          quantity: entry.value.quantity ?? 1,
          price: product.price,
          status: OrderStatus.pending,
        );
      }
    }
    final order = Order(
      userId: cart.userId,
      items: orderItems,
      totalAmount: cart.totalAmount,
    );
    orderDao.saveOrder(order);
    cartDao.deleteCart(cartKey);
    setState(() {
      _loading = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Order placed and cart cleared',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCartItem(DataSnapshot snapshot) {
    final json = snapshot.value as Map<dynamic, dynamic>;
    final cart = Cart.fromJson(json);
    final cartKey = snapshot.key!;
    final items = cart.items;
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5,
        vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...items.entries.map((entry) {
            final productId = entry.key;
            final item = entry.value;
            return FutureBuilder<Product?>(
              future: _getProduct(productId),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return ListTile(
                    title: Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      ),
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
                    leadingWidget = Icon(
                      Icons.shopping_cart,
                      size: ResponsiveHelper.getAdaptiveIconSize(context) * 2,
                      color: AppColors.mutedText,
                    );
                  }
                } else {
                  leadingWidget = Icon(
                    Icons.shopping_cart,
                    size: ResponsiveHelper.getAdaptiveIconSize(context) * 2,
                    color: AppColors.mutedText,
                  );
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
                    'Price: ${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      color: AppColors.secondaryText,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.remove,
                          size: ResponsiveHelper.getAdaptiveIconSize(context),
                          color: AppColors.error,
                        ),
                        onPressed: () => _updateQuantity(cartKey, cart, productId, -1),
                      ),
                      Text(
                        '${item.quantity ?? 1}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.add,
                          size: ResponsiveHelper.getAdaptiveIconSize(context),
                          color: AppColors.success,
                        ),
                        onPressed: () => _updateQuantity(cartKey, cart, productId, 1),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: AppColors.error,
                          size: ResponsiveHelper.getAdaptiveIconSize(context),
                        ),
                        onPressed: () => _deleteItem(cartKey, cart, productId),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.shopping_bag,
                          color: AppColors.success,
                          size: ResponsiveHelper.getAdaptiveIconSize(context),
                        ),
                        tooltip: 'Order this item',
                        onPressed: () => _orderSingleItem(cartKey, cart, productId),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
          Padding(
            padding: ResponsiveHelper.getAdaptivePadding(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cart Total: ${cart.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _checkout(cartKey, cart),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: ResponsiveHelper.getVerticalPadding(context),
                  ),
                  child: Text(
                    'Checkout',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
                        child: Text(
                          'Error loading cart.',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                            color: AppColors.error,
                          ),
                        ),
                      );
                    }
                    final data = snapshot.data?.snapshot.value;
                    if (data == null) {
                      return Center(
                        child: Text(
                          'No items in cart.',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                            color: AppColors.secondaryText,
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
