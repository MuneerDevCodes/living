import 'package:flutter/material.dart';
import 'package:living/services/auth_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:living/widgets/alert_success.dart';

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
        builder:
            (context) => AlertDialog(
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
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
