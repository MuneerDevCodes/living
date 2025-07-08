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
            child: Center(
              child: SingleChildScrollView(
                padding: ResponsiveHelper.getAdaptivePadding(context),
                child: Container(
                  constraints: ResponsiveHelper.getFlexibleConstraints(context),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getAdaptiveBorderRadius(context),
                      ),
                    ),
                    child: Padding(
                      padding: ResponsiveHelper.getCardPadding(context),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            showLogin ? 'Login to Living' : 'Create Your Account',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 24),
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                          showLogin ? const LoginScreen() : const RegisterScreen(),
                          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                          TextButton(
                            onPressed: toggle,
                            child: Text(
                              showLogin
                                  ? "Don't have an account? Register"
                                  : "Already have an account? Login",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
}
