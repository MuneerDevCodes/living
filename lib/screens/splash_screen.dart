import 'package:flutter/material.dart';
import 'dart:async';
import '../screens/home_page.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_page.dart';

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
  bool? _onboardingCompleted;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
    
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
    
    // Start animations after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnimations();
    });
  }

  void _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('onboarding_completed') ?? false;
    if (mounted) {
      setState(() {
        _onboardingCompleted = completed;
      });
      // Navigate to next screen after 4 seconds
      Timer(const Duration(seconds: 6), () {
        _navigateToNext();
      });
    }
  }

  void _startAnimations() async {
    if (!mounted) return;
    
    try {
      // Start logo animation
      await _logoController.forward();
      
      // Start text animation after logo animation
      if (mounted) {
        await _textController.forward();
      }
    } catch (e) {
      // Handle any animation errors gracefully
      if (mounted) {
        _navigateToNext();
      }
    }
  }

  void _navigateToNext() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    if (_onboardingCompleted == true) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomePage(),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const OnboardingPage(),
        ),
      );
    }
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
                                color: Colors.black.withValues(alpha: 0.2),
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
                
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 4.0),
                
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
                            Text(
                              'Welcome to',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 24),
                                color: AppColors.white,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8),
                            Text(
                              'Living',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 48),
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                              ),
                            ),
                            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 1.6),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 2.0,
                                vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Your Sustainable Living Companion',
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                                  color: AppColors.white,
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
                
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 6.0),
                
                // Loading indicator
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    final opacity = _textController.value.clamp(0.0, 1.0);
                    
                    return Opacity(
                      opacity: opacity,
                      child: SizedBox(
                        width: ResponsiveHelper.getAdaptiveSpacing(context) * 4.0,
                        height: ResponsiveHelper.getAdaptiveSpacing(context) * 4.0,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
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