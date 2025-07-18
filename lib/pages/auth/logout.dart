import 'package:flutter/material.dart';
import 'package:living/services/auth_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:living/widgets/alert_success.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/widgets/loader.dart';

/// Logout widget handles user sign-out and shows a responsive loader and success alert.
class Logout extends StatefulWidget {
  const Logout({super.key});

  @override
  State<Logout> createState() => _LogoutState();
}

class _LogoutState extends State<Logout> {
  @override
  void initState() {
    super.initState();
    _logout();
  }

  Future<void> _logout() async {
    await AuthService().signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('uid');
    if (mounted) {
      // Show a success alert before navigating
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: const AlertSuccess('You have been logged out.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/auth',
                  (route) => false,
                );
              },
              child: Text(
                'OK',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  /// Build method for the logout screen, using only ResponsiveHelper and AppTheme/AppColors.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: ResponsiveHelper.getAdaptiveIconSize(context) * 2,
              height: ResponsiveHelper.getAdaptiveIconSize(context) * 2,
              child: const Loader(),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            Text(
              'Logging out...',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
