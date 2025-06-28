import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:living/models/product_model.dart';
import 'package:living/services/product_dao.dart';
import 'package:living/widgets/product_modal.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/screens/product_detail_page.dart';
import 'package:living/widgets/loader.dart';
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
      builder:
          (ctx) => ProductModal(
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

    // Use imageUrl for product image
    Widget imageWidget;
    if (product.imageUrl.isNotEmpty) {
      try {
        imageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.memory(
            base64Decode(product.imageUrl),
            width: 60,
            height: 80,
            fit: BoxFit.fill,
          ),
        );
      } catch (_) {
        imageWidget = const Icon(Icons.image, size: 60, color: Colors.grey);
      }
    } else {
      imageWidget = const Icon(Icons.image, size: 60, color: Colors.grey);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: ListTile(
        leading: imageWidget,
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.category.name),
            Text('Eco Rating: ${product.ecoRating}'),
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
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showProductModal(product: product, key: snapshot.key),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
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
      drawer: BookstoreHeader.buildDrawer(context), // Use your header widget
      body: Column(
        children: [
          const BookstoreHeader(), // Use your header widget
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
                      return const Center(child: Text('Error loading products'));
                    }
                    final data = snapshot.data?.snapshot.value;
                    if (data == null) {
                      return const Center(child: Text('No products found.'));
                    }
                    final products = <MapEntry<String, dynamic>>[];
                    final map = Map<String, dynamic>.from(data as dynamic);
                    map.forEach((key, value) {
                      products.add(MapEntry(key, value));
                    });
                    return ListView.builder(
                      controller: _scrollController,
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
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: () => _showProductModal(),
                    tooltip: 'Add Product',
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ),
          const BookstoreFooter(), // Use your footer widget
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
