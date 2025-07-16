import 'package:flutter/material.dart';
import 'package:living/services/auth_helper.dart';
import 'package:living/pages/auth/login.dart';
import 'package:living/pages/auth/register.dart';
import 'package:living/style/theme.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/widgets/header.dart';
import 'package:living/style/responsive_helper.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  static const String routeName = '/auth';

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool showLogin = true;

  @override
  void initState() {
    super.initState();
    // If already logged in, go to home
    if (AuthService().currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/');
      });
    }
  }

  void toggle() {
    setState(() {
      showLogin = !showLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: Header.buildDrawer(context),
      body: Column(
        children: [
          const Header(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.05),
                    Colors.white,
                  ],
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding: ResponsiveHelper.getAdaptivePadding(context),
                  child: Container(
                    constraints: ResponsiveHelper.getFlexibleConstraints(context),
                    child: _buildAuthContainer(),
                  ),
                ),
              ),
            ),
          ),
          Footer(),
        ],
      ),
    );
  }

  Widget _buildAuthContainer() {
    if (ResponsiveHelper.isMobile(context)) {
      return _buildMobileLayout();
    } else {
      return _buildDesktopLayout();
    }
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Welcome section
        _buildWelcomeSection(),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 1.5),
        // Auth form card
        _buildAuthCard(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left side - Welcome and info
        Expanded(
          flex: 1,
          child: _buildWelcomeSection(),
        ),
        SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 2),
        // Right side - Auth form
        Expanded(
          flex: 1,
          child: _buildAuthCard(),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App logo and name
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveHelper.getAdaptiveGap(context) * 0.5),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.eco,
                  color: Colors.white,
                  size: ResponsiveHelper.getAdaptiveIconSize(context) * 1.5,
                ),
              ),
              SizedBox(width: ResponsiveHelper.getAdaptiveGap(context)),
              Text(
                'Planet Care',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getTitleFontSize(context),
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 1.5),
          
          // Welcome message
          Text(
            'Welcome to Sustainable Living',
            style: TextStyle(
              fontSize: ResponsiveHelper.getSubtitleFontSize(context) * 1.2,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
          
          Text(
            'Join our community and start your journey towards a more sustainable lifestyle. Track your carbon footprint, discover eco-friendly products, and connect with like-minded individuals.',
            style: TextStyle(
              fontSize: ResponsiveHelper.getBodyFontSize(context),
              color: AppColors.secondaryText,
              height: 1.5,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 1.5),
          
          // Features list
          _buildFeaturesList(),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      {'icon': Icons.cloud, 'text': 'Track your carbon footprint'},
      {'icon': Icons.emoji_events, 'text': 'Complete sustainability challenges'},
      {'icon': Icons.recycling, 'text': 'Monitor waste reduction'},
      {'icon': Icons.shopping_cart, 'text': 'Discover eco-friendly products'},
      {'icon': Icons.forum, 'text': 'Connect with the community'},
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
          child: Row(
            children: [
              Icon(
                feature['icon'] as IconData,
                color: AppColors.primary,
                size: ResponsiveHelper.getAdaptiveIconSize(context) * 0.8,
              ),
              SizedBox(width: ResponsiveHelper.getAdaptiveGap(context) * 0.5),
              Expanded(
                                 child: Text(
                   feature['text'] as String,
                   style: TextStyle(
                     fontSize: ResponsiveHelper.getBodyFontSize(context) * 0.9,
                     color: AppColors.secondaryText,
                   ),
                 ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAuthCard() {
    return Card(
      elevation: 8,
      shadowColor: AppColors.shadowLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getAdaptiveBorderRadius(context) * 1.2,
        ),
      ),
      child: Container(
        padding: ResponsiveHelper.getCardPadding(context) * 1.5,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getAdaptiveBorderRadius(context) * 1.2,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              AppColors.primary.withValues(alpha: 0.02),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Auth type indicator
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getAdaptiveSpacing(context),
                vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getAdaptiveBorderRadius(context),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    showLogin ? Icons.login : Icons.person_add,
                    color: AppColors.primary,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveGap(context) * 0.5),
                  Text(
                    showLogin ? 'Sign In' : 'Create Account',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: ResponsiveHelper.getBodyFontSize(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 1.5),
            
            // Title
            Text(
              showLogin ? 'Welcome Back!' : 'Join Our Community',
              style: TextStyle(
                fontSize: ResponsiveHelper.getSubtitleFontSize(context),
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
            
            Text(
              showLogin 
                ? 'Sign in to continue your sustainable journey'
                : 'Create your account to start your eco-friendly adventure',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveHelper.getBodyFontSize(context) * 0.9,
                color: AppColors.secondaryText,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 1.5),
            
            // Auth form
            showLogin ? const LoginScreen() : const RegisterScreen(),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 1.5),
            
            // Toggle button
            _buildToggleButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getAdaptiveBorderRadius(context),
        ),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            showLogin
                ? "Don't have an account? "
                : "Already have an account? ",
            style: TextStyle(
              color: AppColors.secondaryText,
              fontSize: ResponsiveHelper.getBodyFontSize(context) * 0.9,
            ),
          ),
          GestureDetector(
            onTap: toggle,
            child: Text(
              showLogin ? "Sign Up" : "Sign In",
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getBodyFontSize(context) * 0.9,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
