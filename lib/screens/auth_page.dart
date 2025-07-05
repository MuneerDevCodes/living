import 'package:flutter/material.dart';
import 'package:living/services/auth_helper.dart';
import 'package:living/pages/auth/login.dart';
import 'package:living/pages/auth/register.dart';
import 'package:living/style/theme.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/widgets/header.dart';

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
      drawer: Header.buildDrawer(context), // Add the drawer here
      body: Column(
        children: [
          const Header(),
          Expanded(
            child: Center(
              child: Card(
                elevation: 6,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        showLogin ? 'Login to Living' : 'Create Your Account',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: blackberry,
                        ),
                      ),
                      const SizedBox(height: 20),
                      showLogin ? const LoginScreen() : const RegisterScreen(),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: toggle,
                        child: Text(
                          showLogin
                              ? "Don't have an account? Register"
                              : "Already have an account? Login",
                          style: const TextStyle(
                            color: blackberry,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Footer(),
        ],
      ),
    );
  }
}
