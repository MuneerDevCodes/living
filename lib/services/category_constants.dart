import 'package:flutter/material.dart';

class ProductCategory {
  final String label;
  final IconData icon;
  const ProductCategory(this.label, this.icon);
}

const List<ProductCategory> kProductCategories = [
  ProductCategory('Eco-Friendly', Icons.eco),
  ProductCategory('Home & Garden', Icons.home),
  ProductCategory('Kitchen & Dining', Icons.kitchen),
  ProductCategory('Bath & Personal Care', Icons.cleaning_services),
  ProductCategory('Clothing & Fashion', Icons.checkroom),
  ProductCategory('Electronics', Icons.devices),
  ProductCategory('Sports & Outdoors', Icons.sports_soccer),
  ProductCategory('Books & Media', Icons.menu_book),
  ProductCategory('Toys & Games', Icons.toys),
  ProductCategory('Health & Wellness', Icons.favorite),
];

const List<String> kCertificationCategories = [
  'All',
  'Organic',
  'Fair Trade',
  'Energy Star',
  'Forest Stewardship',
  'Marine Stewardship',
  'Building Standards',
  'Business Standards',
  'Environmental Protection',
];
