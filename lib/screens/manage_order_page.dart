import 'package:flutter/material.dart';
import 'package:living/models/order.dart';
import 'package:living/services/order_dao.dart';
import 'package:living/services/product_dao.dart';
import 'package:living/services/user_dao.dart';
import 'package:living/services/admin_service.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/models/enums.dart';
import 'package:living/models/product_model.dart';
import 'package:living/models/user_model.dart';
import 'dart:convert';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';

/// ManageOrderPage allows admins to manage user orders, using responsive and theme-driven design.
class ManageOrderPage extends StatefulWidget {
  const ManageOrderPage({super.key});
  static const String routeName = '/manage-orders';

  @override
  State<ManageOrderPage> createState() => _ManageOrderPageState();
}

class _ManageOrderPageState extends State<ManageOrderPage> {
  final OrderDao orderDao = OrderDao();
  final ProductDao productDao = ProductDao();
  final UserDao userDao = UserDao();
  final AdminService adminService = AdminService();
  bool _loading = false;
  bool _isAdmin = false;
  bool _isLoading = true;
  String _selectedStatusFilter = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await adminService.isAdmin();
    setState(() {
      _isAdmin = isAdmin;
      _isLoading = false;
    });
  }

  Future<User?> _getUserById(String userId) async {
    try {
      final snapshot = await userDao.getUserList().orderByChild('uuid').equalTo(userId).get();
      if (snapshot.exists && snapshot.children.isNotEmpty) {
        final snap = snapshot.children.first;
        return User.fromJson(snap.value as Map<dynamic, dynamic>);
      }
    } catch (e) {
      print('Error getting user: $e');
    }
    return null;
  }

  List<MapEntry<String, Order>> _filterOrders(List<MapEntry<String, Order>> orders) {
    List<MapEntry<String, Order>> filtered = orders;

    // Filter by status
    if (_selectedStatusFilter != 'All') {
      final status = OrderStatus.values.firstWhere(
        (s) => s.toString().split('.').last.toUpperCase() == _selectedStatusFilter,
        orElse: () => OrderStatus.pending,
      );
      filtered = filtered.where((entry) => entry.value.status == status).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((entry) {
        final order = entry.value;
        final orderId = entry.key.substring(0, 8);
        return orderId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               order.shippingAddress.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               order.paymentMethod.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  Widget _buildOrderCard(String orderKey, Order order, User? user) {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getAdaptiveSpacing(context),
        vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5,
      ),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
      ),
      child: ExpansionTile(
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        leading: Container(
          width: ResponsiveHelper.getAdaptiveIconSize(context) * 2.5,
          height: ResponsiveHelper.getAdaptiveIconSize(context) * 2.5,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.shopping_bag,
            color: AppColors.primary,
            size: ResponsiveHelper.getAdaptiveIconSize(context) * 1.2,
          ),
        ),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order info (Expanded)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.id ?? orderKey.substring(0, 8)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                      color: AppColors.primaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                  Text(
                    'Customer: ${user?.displayname ?? 'Unknown User'}',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                      color: AppColors.secondaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Date: ${DateTime.fromMillisecondsSinceEpoch(order.createdAt).toLocal().toString().split(' ')[0]}',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                      color: AppColors.secondaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3,
                      vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.1,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status),
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3,
                      ),
                    ),
                    child: Text(
                      order.status.toString().split('.').last.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 10),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Amount/items (right side)
            SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${order.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${order.items.length} items',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 10),
                    color: AppColors.secondaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
        subtitle: FutureBuilder<Product?>(
          future: order.items.isNotEmpty 
            ? productDao.getProductById(order.items.values.first.productId)
            : Future.value(null),
          builder: (context, productSnap) {
            if (productSnap.hasData && productSnap.data != null) {
              final product = productSnap.data!;
              return Padding(
                padding: EdgeInsets.only(top: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                child: Row(
                  children: [
                    // Product Image
                    Container(
                      width: ResponsiveHelper.getAdaptiveImageSize(context) * 0.8,
                      height: ResponsiveHelper.getAdaptiveImageSize(context) * 0.8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3,
                        ),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: product.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3,
                            ),
                            child: Image.memory(
                              base64Decode(product.imageUrl),
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            Icons.shopping_bag,
                            size: ResponsiveHelper.getAdaptiveIconSize(context) * 0.6,
                            color: AppColors.mutedText,
                          ),
                    ),
                    SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                    // Product Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 13),
                              color: AppColors.primaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Qty: ${order.items.values.first.quantity} • \$${order.items.values.first.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 11),
                              color: AppColors.secondaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            return SizedBox.shrink();
          },
        ),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
                bottomRight: Radius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
              ),
            ),
            child: Padding(
              padding: ResponsiveHelper.getAdaptivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Details Section
                  _buildSectionHeader('Order Details'),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                  _buildDetailRow('Shipping Address', order.shippingAddress),
                  _buildDetailRow('Payment Method', order.paymentMethod),
                  _buildDetailRow('Subtotal', '\$${order.subtotal.toStringAsFixed(2)}'),
                  _buildDetailRow('Shipping Cost', '\$${order.shippingCost.toStringAsFixed(2)}'),
                  _buildDetailRow('Total', '\$${order.totalAmount.toStringAsFixed(2)}', isTotal: true),
                  
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                  
                  // Order Items Section
                  _buildSectionHeader('Order Items'),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                  ...order.items.entries.map((entry) {
                    final orderItem = entry.value;
                    final itemKey = entry.key;
                    return FutureBuilder<Product?>(
                      future: productDao.getProductById(orderItem.productId),
                      builder: (context, productSnap) {
                        if (!productSnap.hasData) {
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
                        
                        final product = productSnap.data!;
                        return Container(
                          margin: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                          padding: ResponsiveHelper.getAdaptivePadding(context),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.4,
                            ),
                            border: Border.all(color: AppColors.borderLight),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product Image
                              Container(
                                width: ResponsiveHelper.getAdaptiveImageSize(context) * 1.5,
                                height: ResponsiveHelper.getAdaptiveImageSize(context) * 1.5,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.4,
                                  ),
                                  border: Border.all(color: AppColors.borderLight),
                                ),
                                child: product.imageUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.4,
                                        ),
                                        child: Image.memory(
                                          base64Decode(product.imageUrl),
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.background,
                                          borderRadius: BorderRadius.circular(
                                            ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.4,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.shopping_bag,
                                          size: ResponsiveHelper.getAdaptiveIconSize(context),
                                          color: AppColors.mutedText,
                                        ),
                                      ),
                              ),
                              SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
                              // Product Details and Status
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Product name/details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                product.name,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                                                  color: AppColors.primaryText,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: EdgeInsets.symmetric(
                                                      horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3,
                                                      vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.1,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(
                                                        ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'Qty: ${orderItem.quantity}',
                                                      style: TextStyle(
                                                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 11),
                                                        color: AppColors.primary,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                                                  Text(
                                                    '\$${orderItem.price.toStringAsFixed(2)} each',
                                                    style: TextStyle(
                                                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                                                      color: AppColors.secondaryText,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                                              Text(
                                                'Total: \$${(orderItem.quantity * orderItem.price).toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.success,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Status Dropdown (Admin Only)
                                        if (_isAdmin)
                                          Flexible(
                                            fit: FlexFit.loose,
                                            child: Padding(
                                              padding: EdgeInsets.only(left: ResponsiveHelper.getAdaptiveSpacing(context)),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    'Status:',
                                                    style: TextStyle(
                                                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 10),
                                                      color: AppColors.secondaryText,
                                                    ),
                                                  ),
                                                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                                                  Container(
                                                    padding: EdgeInsets.symmetric(
                                                      horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: _getStatusColor(orderItem.status).withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(
                                                        ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3,
                                                      ),
                                                      border: Border.all(color: _getStatusColor(orderItem.status)),
                                                    ),
                                                    child: DropdownButton<OrderStatus>(
                                                      value: orderItem.status,
                                                      underline: Container(),
                                                      icon: Icon(
                                                        Icons.arrow_drop_down,
                                                        size: ResponsiveHelper.getAdaptiveIconSize(context),
                                                        color: _getStatusColor(orderItem.status),
                                                      ),
                                                      items: OrderStatus.values.map((OrderStatus status) {
                                                        return DropdownMenuItem<OrderStatus>(
                                                          value: status,
                                                          child: Text(
                                                            status.toString().split('.').last.toUpperCase(),
                                                            style: TextStyle(
                                                              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 10),
                                                              color: _getStatusColor(status),
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                        );
                                                      }).toList(),
                                                      onChanged: (OrderStatus? newStatus) {
                                                        if (newStatus != null && newStatus != orderItem.status) {
                                                          _updateOrderItemStatus(orderKey, order, itemKey, orderItem, newStatus);
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }).toList(),
                  
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                  
                  // Order Actions (Admin Only)
                  if (_isAdmin) ...[
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                    Container(
                      padding: ResponsiveHelper.getAdaptivePadding(context),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.4,
                        ),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Actions',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _updateOrderStatus(orderKey, order, OrderStatus.processing),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.info,
                                    foregroundColor: Colors.white,
                                    padding: ResponsiveHelper.getAdaptivePadding(context),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.6,
                                      ),
                                    ),
                                  ),
                                  icon: Icon(
                                    Icons.play_arrow,
                                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                                  ),
                                  label: Text(
                                    'Process',
                                    style: TextStyle(
                                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _updateOrderStatus(orderKey, order, OrderStatus.shipped),
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
                                    Icons.local_shipping,
                                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                                  ),
                                  label: Text(
                                    'Ship',
                                    style: TextStyle(
                                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _updateOrderStatus(orderKey, order, OrderStatus.delivered),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                    padding: ResponsiveHelper.getAdaptivePadding(context),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.6,
                                      ),
                                    ),
                                  ),
                                  icon: Icon(
                                    Icons.check_circle,
                                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                                  ),
                                  label: Text(
                                    'Deliver',
                                    style: TextStyle(
                                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label (fixed width)
          SizedBox(
            width: ResponsiveHelper.isMobile(context) ? 80 : 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                color: AppColors.secondaryText,
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
          // Value (expanded with overflow protection)
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                color: isTotal ? AppColors.primary : AppColors.primaryText,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _updateOrderItemStatus(String orderKey, Order order, String itemKey, OrderItem orderItem, OrderStatus newStatus) {
    final updatedItems = Map<String, OrderItem>.from(order.items);
    updatedItems[itemKey] = OrderItem(
      productId: orderItem.productId,
      quantity: orderItem.quantity,
      price: orderItem.price,
      status: newStatus,
    );
    
    final updatedOrder = order.copyWith(
      items: updatedItems,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    
    orderDao.updateOrder(orderKey, updatedOrder);
    setState(() {});
  }

  void _updateOrderStatus(String orderKey, Order order, OrderStatus newStatus) {
    final updatedOrder = order.copyWith(
      status: newStatus,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    
    orderDao.updateOrder(orderKey, updatedOrder);
    setState(() {});
  }

  /// Build method for the manage order page, using only ResponsiveHelper and AppTheme/AppColors.
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Loader()),
      );
    }

    if (!_isAdmin) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: Header.buildDrawer(context),
      body: Column(
          children: [
            const Header(),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      size: ResponsiveHelper.getAdaptiveIconSize(context) * 3,
                      color: AppColors.error,
                    ),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                    Text(
                      'Access Denied',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 20),
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                    Text(
                      'You need admin privileges to access this page.',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        color: AppColors.secondaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const Footer(),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: Header.buildDrawer(context),
      body: SafeArea(
        child: Column(
        children: [
          const Header(),
          Expanded(
            child: Stack(
              children: [
                if (_loading) const Positioned.fill(child: Loader()),
                  Column(
                    children: [
                      // Filters and Search Section
                      Container(
                        padding: ResponsiveHelper.getAdaptivePadding(context),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Search Bar
                            TextField(
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Search orders...',
                                prefixIcon: Icon(Icons.search, color: AppColors.mutedText),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.6,
                                  ),
                                ),
                                filled: true,
                                fillColor: AppColors.background,
                              ),
                            ),
                            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                            
                            // Status Filter
                            Row(
                              children: [
                                Text(
                                  'Filter by Status: ',
                                  style: TextStyle(
                                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Expanded(
                                  child: DropdownButton<String>(
                                    value: _selectedStatusFilter,
                                    isExpanded: true,
                                    items: ['All', ...OrderStatus.values.map((s) => s.toString().split('.').last.toUpperCase())]
                                        .map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedStatusFilter = newValue!;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Orders List
                      Expanded(
                        child: StreamBuilder(
                  stream: orderDao.getOrderList().onValue,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Loader();
                    }
                    if (snapshot.hasError) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: ResponsiveHelper.getAdaptiveIconSize(context) * 3,
                                      color: AppColors.error,
                                    ),
                                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                                    Text(
                                      'Error loading orders',
                                      style: TextStyle(
                                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            final data = snapshot.data?.snapshot.value;
                            if (data == null) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.shopping_bag_outlined,
                                      size: ResponsiveHelper.getAdaptiveIconSize(context) * 3,
                                      color: AppColors.mutedText,
                                    ),
                                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                                    Text(
                                      'No orders found',
                                      style: TextStyle(
                                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            try {
                              final orders = (data as Map).entries.map((entry) {
                                return MapEntry<String, Order>(
                                  entry.key.toString(),
                                  Order.fromJson(Map<dynamic, dynamic>.from(entry.value)),
                                );
                              }).toList();
                              
                              final filteredOrders = _filterOrders(orders);
                              
                              if (filteredOrders.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                      Icon(
                                        Icons.filter_list,
                                        size: ResponsiveHelper.getAdaptiveIconSize(context) * 3,
                                        color: AppColors.mutedText,
                                      ),
                                      SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                                                  Text(
                                        'No orders match your filters',
                                        style: TextStyle(
                                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                                          color: AppColors.secondaryText,
                                        ),
                                                  ),
                                                ],
                                              ),
                                            );
                              }
                              
                              return ListView.builder(
                                padding: ResponsiveHelper.getAdaptivePadding(context),
                                itemCount: filteredOrders.length,
                                itemBuilder: (context, index) {
                                  final orderKey = filteredOrders[index].key;
                                  final order = filteredOrders[index].value;
                                  return FutureBuilder<User?>(
                                    future: _getUserById(order.userId),
                                    builder: (context, userSnap) {
                                      return _buildOrderCard(orderKey, order, userSnap.data);
                                          },
                                        );
                                      },
                              );
                            } catch (e) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: ResponsiveHelper.getAdaptiveIconSize(context) * 3,
                                      color: AppColors.error,
                                    ),
                                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                                    Text(
                                      'Error processing orders',
                                      style: TextStyle(
                                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                                        color: AppColors.error,
                                      ),
                                    ),
                                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                                    Text(
                                      'Please try again',
                                      style: TextStyle(
                                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                ),
              ],
            ),
          ),
            const Footer(),
        ],
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.processing:
        return AppColors.info;
      case OrderStatus.shipped:
        return AppColors.primary;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.canceled:
        return AppColors.error;
      default:
        return AppColors.secondaryText;
    }
  }
}
