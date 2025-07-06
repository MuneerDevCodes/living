import 'package:flutter/material.dart';
import 'package:living/models/order.dart';
import 'package:living/services/order_dao.dart';
import 'package:living/services/product_dao.dart';
import 'package:living/models/product_model.dart';
import 'package:living/models/enums.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/services/auth_helper.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';
import 'dart:convert';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});
  static const String routeName = '/order';

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final OrderDao orderDao = OrderDao();
  final ProductDao productDao = ProductDao();
  final ScrollController _scrollController = ScrollController();
  String? _userId;
  final _loading = false;

  @override
  void initState() {
    super.initState();
    final user = AuthService().currentUser;
    _userId = user?.uid;
  }

  void _cancelOrder(String key, Order order, String itemKey) {
    // Create a new map with updated status for the specific item
    final updatedItems = Map<String, OrderItem>.from(order.items);
    final item = updatedItems[itemKey];
    if (item != null) {
      updatedItems[itemKey] = OrderItem(
        productId: item.productId,
        quantity: item.quantity,
        price: item.price,
        status: OrderStatus.canceled,
      );
      final updatedOrder = Order(
        userId: order.userId,
        items: updatedItems,
        totalAmount: order.totalAmount,
      );
      orderDao.updateOrder(key, updatedOrder);
      setState(() {});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order item cancelled.',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
          ),
        );
      }
    }
  }

  Widget _buildOrderItem(DataSnapshot snapshot) {
    final json = snapshot.value as Map<dynamic, dynamic>;
    final order = Order.fromJson(json);
    final orderKey = snapshot.key!;
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5,
        vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3,
      ),
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Items:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.items.length,
              itemBuilder: (context, idx) {
                final entry = order.items.entries.elementAt(idx);
                final orderItem = entry.value;
                final itemKey = entry.key;
                final isPending = orderItem.status == OrderStatus.pending;
                return FutureBuilder<Product?>(
                  future: productDao.getProductById(orderItem.productId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ListTile(
                        title: Loader(),
                        titleTextStyle: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        ),
                      );
                    }
                    final product = snapshot.data;
                    final imageSize = ResponsiveHelper.getAdaptiveImageSize(context);
                    
                    Widget leadingWidget;
                    if (product != null && product.imageUrl.isNotEmpty) {
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
                        product?.name ?? 'Unknown',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          Text(
                            'Quantity: ${orderItem.quantity}',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                              color: AppColors.secondaryText,
                            ),
                          ),
                          SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.6),
                          Text(
                            'Status: ${orderItem.status.toString().split('.').last}',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 13),
                              color: AppColors.secondaryText,
                            ),
                          ),
                          if (isPending)
                            IconButton(
                              icon: Icon(
                                Icons.cancel,
                                color: AppColors.warning,
                                size: ResponsiveHelper.getAdaptiveIconSize(context),
                              ),
                              onPressed: () => _cancelOrder(orderKey, order, itemKey),
                              tooltip: 'Cancel Order',
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
            Text(
              'Total: \$${order.totalAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                color: AppColors.primary,
              ),
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
                if (_loading) const Positioned.fill(child: Loader()),
                StreamBuilder(
                  stream:
                      orderDao
                          .getOrderList()
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
                          'Error loading orders.',
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
                          'No orders found.',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                            color: AppColors.secondaryText,
                          ),
                        ),
                      );
                    }
                    final orders = <MapEntry<String, dynamic>>[];
                    final map = Map<String, dynamic>.from(data as dynamic);
                    map.forEach((key, value) {
                      orders.add(MapEntry(key, value));
                    });
                    return ListView.builder(
                      controller: _scrollController,
                      padding: ResponsiveHelper.getAdaptivePadding(context),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final entry = orders[index];
                        final snapshot = DataSnapshotFake(
                          entry.key,
                          entry.value,
                        );
                        return _buildOrderItem(snapshot);
                      },
                    );
                  },
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

// Helper class to fake DataSnapshot for compatibility with _buildOrderItem
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
