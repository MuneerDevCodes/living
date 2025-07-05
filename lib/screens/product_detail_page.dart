import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:living/models/product_model.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/widgets/loader.dart';

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
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
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
              width: 120,
              height: 160,
              fit: BoxFit.fill,
            )
            : Container(
              width: 120,
              height: 160,
              color: Colors.grey[300],
              child: const Icon(Icons.image, size: 60),
            );

    return Scaffold(
      drawer: Header.buildDrawer(context),
      body: Column(
        children: [
          const Header(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      cover,
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Category: ${product.category.name}'),
                            Text('Eco Rating: ${product.ecoRating}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    product.description,
                    style: const TextStyle(fontSize: 15),
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
}
