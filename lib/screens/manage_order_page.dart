import 'package:flutter/material.dart';
import 'package:living/models/order.dart';
import 'package:living/services/order_dao.dart';
import 'package:living/services/product_dao.dart';
import 'package:living/services/user_dao.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/models/enums.dart';
import 'package:living/models/product_model.dart';
import 'package:living/models/user_model.dart';
import 'dart:convert';
import 'package:living/style/responsive_helper.dart';

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
  final _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Header.buildDrawer(context), // Add the drawer here
      body: Column(
        children: [
          const Header(),
          Expanded(
            child: Stack(
              children: [
                if (_loading) const Positioned.fill(child: Loader()),
                StreamBuilder(
                  stream: orderDao.getOrderList().onValue,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Loader();
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text('Error loading orders.'));
                    }
                    final data = snapshot.data?.snapshot.value;
                    if (data == null) {
                      return const Center(child: Text('No orders found.'));
                    }
                    final orders = (data as Map).entries.toList();
                    return ListView.builder(
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final orderKey = orders[index].key;
                        final order = Order.fromJson(
                          Map<dynamic, dynamic>.from(orders[index].value),
                        );
                        return FutureBuilder<User?>(
                          future: userDao.getUserById(order.userId),
                          builder: (context, userSnap) {
                            if (!userSnap.hasData) {
                              return const ListTile(
                                title: Text('Loading user...'),
                              );
                            }
                            final user = userSnap.data!;
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'User: ${user.displayname}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Address: ${user.shippingAddress}',
                                      style: const TextStyle(),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Items:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: order.items.length,
                                      itemBuilder: (context, idx) {
                                        final entry = order.items.entries
                                            .elementAt(idx);
                                        final orderItem = entry.value;
                                        final itemKey = entry.key;
                                        return FutureBuilder<Product?>(
                                          future: productDao.getProductById(
                                            orderItem.productId,
                                          ),
                                          builder: (context, productSnap) {
                                            if (!productSnap.hasData) {
                                              return const ListTile(
                                                title: Loader(),
                                              );
                                            }
                                            final product = productSnap.data!;
                                            return ListTile(
                                              leading:
                                                  (product
                                                          .imageUrl
                                                          .isNotEmpty)
                                                      ? ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        child: Image.memory(
                                                          base64Decode(
                                                            product.imageUrl,
                                                          ),
                                                          width: 40,
                                                          height: 60,
                                                          fit: BoxFit.fill,
                                                        ),
                                                      )
                                                      : const Icon(
                                                        Icons.shopping_cart,
                                                        size: 40,
                                                      ),
                                              title: Text(product.name),
                                              subtitle: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Quantity: ${orderItem.quantity}',
                                                  ),
                                                  Text(
                                                    'Price: \$${orderItem.price.toStringAsFixed(2)}',
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        'Status: ${orderItem.status.toString().split('.').last}',
                                                      ),
                                                      const SizedBox(width: 8),
                                                      DropdownButton<
                                                        OrderStatus
                                                      >(
                                                        value: orderItem.status,
                                                        items:
                                                            OrderStatus.values.map((
                                                              OrderStatus
                                                              status,
                                                            ) {
                                                              return DropdownMenuItem<
                                                                OrderStatus
                                                              >(
                                                                value: status,
                                                                child: Text(
                                                                  status
                                                                      .toString()
                                                                      .split(
                                                                        '.',
                                                                      )
                                                                      .last,
                                                                ),
                                                              );
                                                            }).toList(),
                                                        onChanged: (
                                                          OrderStatus?
                                                          newStatus,
                                                        ) {
                                                          if (newStatus !=
                                                                  null &&
                                                              newStatus !=
                                                                  orderItem
                                                                      .status) {
                                                            final updatedItems =
                                                                Map<
                                                                  String,
                                                                  OrderItem
                                                                >.from(
                                                                  order.items,
                                                                );
                                                            updatedItems[itemKey] =
                                                                OrderItem(
                                                                  productId:
                                                                      orderItem
                                                                          .productId,
                                                                  quantity:
                                                                      orderItem
                                                                          .quantity,
                                                                  price:
                                                                      orderItem
                                                                          .price,
                                                                  status:
                                                                      newStatus,
                                                                );
                                                            final updatedOrder = Order(
                                                              userId:
                                                                  order.userId,
                                                              items:
                                                                  updatedItems,
                                                              totalAmount:
                                                                  order
                                                                      .totalAmount,
                                                            );
                                                            orderDao
                                                                .updateOrder(
                                                                  orderKey,
                                                                  updatedOrder,
                                                                );
                                                            setState(() {});
                                                          }
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Total: \$${order.totalAmount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
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
