import 'package:flutter/material.dart';
import 'package:living/routes/routes_guard.dart';
import 'package:living/style/theme.dart';
import 'package:living/screens/splash_screen.dart';
import 'package:living/screens/home_page.dart';
import 'package:living/screens/onboarding_page.dart';
import 'package:living/services/performance_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Enable offline persistence for Realtime Database on non-web platforms
  if (!kIsWeb) {
    FirebaseDatabase.instance.setPersistenceEnabled(true);
  }
  
  // Initialize performance optimizations
  await _initializePerformanceOptimizations();
  
  runApp(const MyApp());
}

/// Initialize performance optimizations for the app
Future<void> _initializePerformanceOptimizations() async {
  try {
    // Configure image cache settings
    PaintingBinding.instance.imageCache.maximumSize = 1000; // Increase cache size
    PaintingBinding.instance.imageCache.maximumSizeBytes = 100 << 20; // 100 MB
    
    // Clear any existing image cache on startup for fresh performance
    await PerformanceService.clearImageCache();
    
    debugPrint('Performance optimizations initialized successfully');
  } catch (e) {
    debugPrint('Failed to initialize performance optimizations: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planet Care',
      theme: AppTheme.lightTheme,
      home: const AppRoot(),
      onGenerateRoute: guardedRoute,
      debugShowCheckedModeBanner: false,
      navigatorKey: GlobalKey<NavigatorState>(),
      builder: (context, child) {
        return ScrollConfiguration(
        behavior: NoScrollbarBehavior(),
        child: child!,
        );
      },
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _showSplash = false;
  bool? _onboardingCompleted;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    final prefs = await SharedPreferences.getInstance();
    final splashShown = prefs.getBool('splash_shown_once') ?? false;
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    if (!splashShown) {
      setState(() {
        _showSplash = true;
        _onboardingCompleted = onboardingCompleted;
        _initialized = true;
      });
      await Future.delayed(const Duration(seconds: 3)); // Splash duration
      await prefs.setBool('splash_shown_once', true);
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    } else {
      setState(() {
        _showSplash = false;
        _onboardingCompleted = onboardingCompleted;
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_showSplash) {
      return const SplashScreen();
    }
    if (_onboardingCompleted == false) {
      return const OnboardingPage();
    }
    return const HomePage();
  }
}
