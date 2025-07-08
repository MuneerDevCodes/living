import 'package:flutter/material.dart';
import 'package:living/routes/routes_guard.dart';
import 'package:living/style/theme.dart';
import 'package:living/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
      title: 'Living App',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      onGenerateRoute: guardedRoute,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => ScrollConfiguration(
        behavior: NoScrollbarBehavior(),
        child: child!,
      ),
    );
  }
}
