import 'package:flutter/material.dart';
import 'package:living/screens/splash_screen.dart';
import 'package:living/screens/contact_us_page.dart';
import 'package:living/screens/home_page.dart';
import 'package:living/screens/auth_page.dart';
import 'package:living/pages/auth/logout.dart';
import 'package:living/screens/about_us_page.dart';
import 'package:living/screens/faq_page.dart';
import 'package:living/screens/search_page.dart';
import 'package:living/screens/manage_product_page.dart';
import 'package:living/screens/cart_page.dart';
import 'package:living/screens/wish_page.dart';
import 'package:living/screens/order_page.dart';
import 'package:living/screens/profile_page.dart';
import 'package:living/screens/product_detail_page.dart';
import 'package:living/screens/manage_category_page.dart';
import 'package:living/screens/manage_order_page.dart';
import 'package:living/screens/manage_contact_us_page.dart';
import 'package:living/screens/carbon_footprint_page.dart';
import 'package:living/screens/carbon_history_page.dart';
import 'package:living/screens/carbon_insights_page.dart';
import 'package:living/screens/challenges_page.dart';
import 'package:living/screens/certifications_page.dart';
import 'package:living/screens/waste_tracker_page.dart';
import 'package:living/screens/energy_tips_page.dart';
import 'package:living/screens/eco_travel_page.dart';
import 'package:living/screens/educational_content_page.dart';
import 'package:living/screens/progress_dashboard_page.dart';
import 'package:living/screens/gallery_page.dart';
import 'package:living/screens/forum_page.dart';
import 'package:living/screens/recipes_page.dart';
import 'package:living/screens/manage_challenges_page.dart';
import 'package:living/screens/manage_educational_content_page.dart';
import 'package:living/screens/onboarding_page.dart';
import 'package:living/screens/settings_page.dart';

// Public routes (no authentication required)
final Map<String, WidgetBuilder> publicRoutes = {
  '/splash': (context) => const SplashScreen(),
  '/onboarding': (context) => const OnboardingPage(),
  '/': (context) => const HomePage(),
  '/home': (context) => const HomePage(),
  '/auth': (context) => const AuthPage(),
  '/contact-us': (context) => const ContactUsPage(),
  '/about-us': (context) => const AboutUsPage(),
  '/faq': (context) => const FAQPage(),
  '/search': (context) => const SearchPage(),
  '/product-detail':
      (context) => ProductDetailPage(
        productKey:
            (ModalRoute.of(context)?.settings.arguments
                as Map?)?['productKey'] ??
            '',
      ),
  '/gallery': (context) => const GalleryPage(),
  '/certifications': (context) => const CertificationsPage(),
  '/energy-tips': (context) => const EnergyTipsPage(),
  '/eco-travel': (context) => const EcoTravelPage(),
  '/educational-content': (context) => const EducationalContentPage(),
  '/recipes': (context) => const RecipesPage(),
};

// Protected routes (authentication required)
final Map<String, WidgetBuilder> protectedRoutes = {
  '/logout': (context) => const Logout(),
  '/cart': (context) => const CartPage(),
  '/wishlist': (context) => const WishPage(),
  '/orders': (context) => const OrderPage(),
  '/profile': (context) => const ProfilePage(),
  '/settings': (context) => const SettingsPage(),
  '/carbon-footprint': (context) => const CarbonFootprintPage(),
  '/carbon-history': (context) => const CarbonHistoryPage(),
  '/carbon-insights': (context) => const CarbonInsightsPage(),
  '/challenges': (context) => const ChallengesPage(),
  '/waste-tracker': (context) => const WasteTrackerPage(),
  '/progress-dashboard': (context) => const ProgressDashboardPage(),
  '/forum': (context) => const ForumPage(),
};

// Admin routes (admin access required)
final Map<String, WidgetBuilder> adminRoutes = {
  '/manage-categories': (context) => const ManageCategoryPage(),
  '/manage-orders': (context) => const ManageOrderPage(),
  '/manage-products': (context) => const ManageProductPage(),
  '/manage-contact-us': (context) => const ManageContactUsPage(),
  '/manage-challenges': (context) => const ManageChallengesPage(),
  '/manage-educational-content':
      (context) => const ManageEducationalContentPage(),
};

// Combined routes map
final Map<String, WidgetBuilder> routes = {
  ...publicRoutes,
  ...protectedRoutes,
  ...adminRoutes,
};

// List of routes that do NOT require authentication
const List<String> unprotectedRoutes = [
  '/splash',
  '/onboarding',
  '/',
  '/home',
  '/auth',
  '/contact-us',
  '/about-us',
  '/search',
  '/faq',
  '/product-detail',
  '/gallery',
  '/energy-tips',
  '/recipes',
];

// List of routes that DO require authentication
const List<String> protectedRoutesList = [
  '/logout',
  '/cart',
  '/wishlist',
  '/order',
  '/profile',
  '/settings',
  '/carbon-footprint',
  '/carbon-history',
  '/carbon-insights',
  '/challenges',
  '/certifications',
  '/waste-tracker',
  '/progress-dashboard',
  '/forum',
  '/educational-content',
  '/eco-travel',
];

// List of routes that ONLY admin users can access
const List<String> adminOnlyRoutes = [
  '/manage-products',
  '/manage-categories',
  '/manage-orders',
  '/manage-contact-us',
  '/manage-challenges',
  '/manage-educational-content',
];
