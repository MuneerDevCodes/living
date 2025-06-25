import 'package:flutter/material.dart';
import 'package:living/services/validate.dart';
import 'package:living/services/auth_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:living/widgets/alert_error.dart';
import 'package:living/widgets/alert_success.dart';
import 'package:living/widgets/loader.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Only for FirebaseAuthException
import 'package:living/services/user_dao.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _saveUserToPrefs(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', uid);
  }

  void _login() async {
    setState(() {
      _error = null;
    });
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _loading = true);
      try {
        final user = await AuthService().signIn(
          _emailCtrl.text,
          _passCtrl.text,
        );
        if (user != null) {
          // Verify user role
          final userDao = UserDao();
          final userRole = await userDao.getUserRole(user.uid);

          if (userRole == null) {
            setState(
              () => _error = "User role not found. Please contact support.",
            );
            return;
          }

          await _saveUserToPrefs(user.uid);
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/');
          }
        }
      } on FirebaseAuthException catch (e) {
        setState(() => _error = e.message ?? "Authentication failed");
      } catch (e) {
        setState(() => _error = "An unexpected error occurred");
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Loader()
        : Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AlertError(
                    _error!,
                    onClose: () => setState(() => _error = null),
                  ),
                ),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: validateEmail,
              ),
              TextFormField(
                controller: _passCtrl,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: validatePass,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed:
                      _loading
                          ? null
                          : () async {
                            final emailCtrl = TextEditingController(
                              text: _emailCtrl.text,
                            );
                            final result = await showDialog<String>(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('Reset Password'),
                                    content: TextField(
                                      controller: emailCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Enter your email',
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(context).pop(),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed:
                                            () => Navigator.of(
                                              context,
                                            ).pop(emailCtrl.text),
                                        child: const Text('Send Reset Link'),
                                      ),
                                    ],
                                  ),
                            );
                            if (result != null && result.isNotEmpty) {
                              try {
                                await AuthService().sendPasswordResetEmail(
                                  result,
                                );
                                if (context.mounted) {
                                  // Show success alert
                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          content: AlertSuccess(
                                            'Password reset email sent.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () =>
                                                      Navigator.of(
                                                        context,
                                                      ).pop(),
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          content: AlertError(
                                            'Failed to send reset email: $e',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () =>
                                                      Navigator.of(
                                                        context,
                                                      ).pop(),
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        ),
                                  );
                                }
                              }
                            }
                          },
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _login,
                child: const Text('Login'),
              ),
            ],
          ),
        );
  }
}
