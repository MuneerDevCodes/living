import 'package:flutter/material.dart';
import 'package:living/style/theme.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/services/auth_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// OnboardingPage displays the onboarding flow for new users, using responsive and theme-driven design.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      title: 'Welcome to Planet Care',
      subtitle: 'Your journey to sustainable living starts here',
      description: 'Join our community and discover how small changes can make a big impact on our planet.',
      icon: Icons.eco,
      color: AppColors.primary,
    ),
    OnboardingStep(
      title: 'Track Your Impact',
      subtitle: 'Monitor your carbon footprint',
      description: 'Understand your environmental impact and track your progress towards a more sustainable lifestyle.',
      icon: Icons.cloud,
      color: AppColors.secondary,
    ),
    OnboardingStep(
      title: 'Discover Eco-Friendly Products',
      subtitle: 'Shop sustainably',
      description: 'Find and purchase products that align with your environmental values.',
      icon: Icons.shopping_cart,
      color: AppColors.tertiary,
    ),
    OnboardingStep(
      title: 'Join the Community',
      subtitle: 'Connect with like-minded people',
      description: 'Share your journey, participate in challenges, and learn from others in our sustainable living community.',
      icon: Icons.forum,
      color: AppColors.primary,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _getStarted();
    }
  }

  void _getStarted() async {
    // Mark onboarding as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  /// Build method for the onboarding page, using only ResponsiveHelper and AppTheme/AppColors.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  return _buildOnboardingStep(_steps[index]);
                },
              ),
            ),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingStep(OnboardingStep step) {
    return Padding(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: ResponsiveHelper.getAdaptiveImageSize(context) * 2,
            height: ResponsiveHelper.getAdaptiveImageSize(context) * 2,
            decoration: BoxDecoration(
              color: step.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getAdaptiveImageSize(context),
              ),
            ),
            child: Icon(
              step.icon,
              size: ResponsiveHelper.getAdaptiveImageSize(context),
              color: step.color,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 2),
          
          // Title
          Text(
            step.title,
            style: TextStyle(
              fontSize: ResponsiveHelper.getTitleFontSize(context),
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
          
          // Subtitle
          Text(
            step.subtitle,
            style: TextStyle(
              fontSize: ResponsiveHelper.getSubtitleFontSize(context),
              fontWeight: FontWeight.w600,
              color: step.color,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          
          // Description
          Text(
            step.description,
            style: TextStyle(
              fontSize: ResponsiveHelper.getBodyFontSize(context),
              color: AppColors.secondaryText,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      child: Column(
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _steps.length,
              (index) => Container(
                margin: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.getAdaptiveGap(context) * 0.2,
                ),
                width: _currentPage == index 
                    ? ResponsiveHelper.getAdaptiveGap(context) * 2
                    : ResponsiveHelper.getAdaptiveGap(context) * 0.8,
                height: ResponsiveHelper.getAdaptiveGap(context) * 0.8,
                decoration: BoxDecoration(
                  color: _currentPage == index 
                      ? AppColors.primary 
                      : AppColors.borderMedium,
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getAdaptiveGap(context) * 0.4,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 1.5),
          
          // Action buttons
          Row(
            children: [
              // Skip button (only show if not on last page)
              if (_currentPage < _steps.length - 1)
                Expanded(
                  child: TextButton(
                    onPressed: _getStarted,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getBodyFontSize(context),
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              
              // Next/Get Started button
              Expanded(
                flex: 2,
                child: Container(
                  height: ResponsiveHelper.getButtonHeight(context),
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: AppColors.shadowMedium,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getAdaptiveBorderRadius(context),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentPage == _steps.length - 1 
                              ? 'Get Started' 
                              : 'Next',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getBodyFontSize(context) * 1.1,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: ResponsiveHelper.getAdaptiveGap(context) * 0.5),
                        Icon(
                          _currentPage == _steps.length - 1 
                              ? Icons.arrow_forward 
                              : Icons.arrow_forward_ios,
                          size: ResponsiveHelper.getAdaptiveIconSize(context) * 0.8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OnboardingStep {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingStep({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });
} 