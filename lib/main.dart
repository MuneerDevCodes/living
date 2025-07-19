import 'package:flutter/material.dart';
import 'package:living/routes/routes_guard.dart';
import 'package:living/style/theme.dart';
import 'package:living/screens/splash_screen.dart';
import 'package:living/screens/home_page.dart';
import 'package:living/screens/onboarding_page.dart';
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
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planet Care',
      theme: AppTheme.lightTheme,
      home: const AppInitializer(),
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

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isFirstLaunch = true;
  bool _isLoading = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkAppState();
  }

  Future<void> _checkAppState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasLaunchedBefore = prefs.getBool('has_launched_before') ?? false;
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      
      setState(() {
        _isFirstLaunch = !hasLaunchedBefore;
        _showOnboarding = !onboardingCompleted;
        _isLoading = false;
      });
      
      // If it's the first launch, mark it as launched
      if (_isFirstLaunch) {
        await prefs.setBool('has_launched_before', true);
      }
    } catch (e) {
      // If there's an error, default to showing splash screen
      setState(() {
        _isFirstLaunch = true;
        _showOnboarding = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_showOnboarding) {
      return const OnboardingPage();
    }
    
    return _isFirstLaunch ? const SplashScreen() : const HomePage();
  }
}
