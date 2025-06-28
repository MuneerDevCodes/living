import 'package:flutter/material.dart';
import 'package:living/screens/contact_us_page.dart';
import 'package:living/screens/home_page.dart';
import 'package:living/screens/auth_page.dart';
import 'package:living/pages/auth/logout.dart';
import 'package:living/screens/about_us_page.dart';
import 'package:living/screens/faq_page.dart';
//  import 'package:living/screens/search_page.dart';
import 'package:living/screens/manage_product_page.dart';
// import 'package:living/screens/cart_page.dart';
// import 'package:living/screens/wish_page.dart';
// import 'package:living/screens/order_page.dart';
import 'package:living/screens/profile_page.dart';
import 'package:living/screens/product_detail_page.dart';
import 'package:living/screens/manage_category_page.dart';
// import 'package:living/screens/manage_order_page.dart';
import 'package:living/screens/manage_contact_us_page.dart';

// Public routes (no authentication required)
final Map<String, WidgetBuilder> publicRoutes = {
  '/': (context) => const HomePage(),
  '/auth': (context) => const AuthPage(),
  '/contact-us': (context) => const ContactUsPage(),
  '/about-us': (context) => const AboutUsPage(),
  '/faq': (context) => const FAQPage(),
  // '/search': (context) => const SearchPage(),
  '/product-detail':
      (context) => ProductDetailPage(
        productKey:
            (ModalRoute.of(context)?.settings.arguments
                as Map?)?['productKey'] ??
            '',
      ),
};

// Protected routes (authentication required)
final Map<String, WidgetBuilder> protectedRoutes = {
  '/logout': (context) => const Logout(),
  // '/cart': (context) => const CartPage(),
  // '/wishlist': (context) => const WishPage(),
  // '/order': (context) => const OrderPage(),
  '/profile': (context) => const ProfilePage(),
};

// Admin routes (admin access required)
final Map<String, WidgetBuilder> adminRoutes = {
  '/manage-categories': (context) => const ManageCategoryPage(),
  // '/manage-orders': (context) => const ManageOrderPage(),
  '/manage-products': (context) => const ManageProductPage(),
  '/manage-contact-us': (context) => const ManageContactUsPage(),
};

// Combined routes map
final Map<String, WidgetBuilder> routes = {
  ...publicRoutes,
  ...protectedRoutes,
  ...adminRoutes,
};

// List of routes that do NOT require authentication
const List<String> unprotectedRoutes = [
  '/',
  '/auth',
  '/contact-us',
  '/about-us',
  '/search',
  '/faq',
  '/book-detail',
];

// List of routes that DO require authentication
const List<String> protectedRoutesList = [
  '/logout',
  '/cart',
  '/wishlist',
  '/order',
  '/profile',
];

// List of routes that ONLY admin users can access
const List<String> adminOnlyRoutes = [
  '/manage-products',
  '/manage-categories',
  '/manage-orders',
  '/manage-contact-us',
];
