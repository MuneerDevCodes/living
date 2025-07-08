import 'package:flutter/material.dart';
import 'dart:async';
import '../style/theme.dart';
import '../screens/home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Start animations
    _startAnimations();
    
    // Navigate to main app after 2 seconds
    Timer(const Duration(seconds: 4), () {
      _navigateToHome();
    });
  }

  void _startAnimations() async {
    if (!mounted) return;
    
    // Start logo animation
    await _logoController.forward();
    
    // Start text animation after logo animation
    if (mounted) {
      _textController.forward();
    }
  }

  void _navigateToHome() {
    if (!mounted || _hasNavigated) return;
    
    _hasNavigated = true;
    
    // Use pushReplacement to replace the splash screen with home page
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const HomePage(),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E7D32), // Dark green
              Color(0xFF81C784), // Light green
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Icon with animation
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    final scale = _logoController.value.clamp(0.0, 1.0);
                    final opacity = _logoController.value.clamp(0.0, 1.0);
                    
                    return Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(60),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.eco,
                            size: 60,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Welcome text with animation
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    final translateY = 30 * (1 - _textController.value.clamp(0.0, 1.0));
                    final opacity = _textController.value.clamp(0.0, 1.0);
                    
                    return Transform.translate(
                      offset: Offset(0, translateY),
                      child: Opacity(
                        opacity: opacity,
                        child: Column(
                          children: [
                            const Text(
                              'Welcome to',
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Living',
                              style: TextStyle(
                                fontSize: 48,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Your Sustainable Living Companion',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 60),
                
                // Loading indicator
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    final opacity = _textController.value.clamp(0.0, 1.0);
                    
                    return Opacity(
                      opacity: opacity,
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 3,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 