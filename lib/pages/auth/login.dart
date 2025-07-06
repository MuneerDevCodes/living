import 'package:flutter/material.dart';
import 'package:living/services/validate.dart';
import 'package:living/services/auth_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:living/widgets/alert_error.dart';
import 'package:living/widgets/alert_success.dart';
import 'package:living/widgets/loader.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Only for FirebaseAuthException
import 'package:living/services/user_dao.dart';
import 'package:living/style/responsive_helper.dart';

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
                    padding: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                    child: AlertError(
                      _error!,
                      onClose: () => setState(() => _error = null),
                    ),
                  ),
                _buildFormFields(),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                _buildLoginButton(),
              ],
            ),
          );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        TextFormField(
          controller: _emailCtrl,
          decoration: InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.6,
              ),
            ),
            labelStyle: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
            ),
          ),
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
          ),
          validator: validateEmail,
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
        TextFormField(
          controller: _passCtrl,
          decoration: InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.6,
              ),
            ),
            labelStyle: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
            ),
          ),
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
          ),
          obscureText: true,
          validator: validatePass,
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _loading
                ? null
                : () async {
                    final emailCtrl = TextEditingController(
                      text: _emailCtrl.text,
                    );
                    final result = await showDialog<String>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(
                          'Reset Password',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: TextField(
                          controller: emailCtrl,
                          decoration: InputDecoration(
                            labelText: 'Enter your email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.6,
                              ),
                            ),
                            labelStyle: TextStyle(
                              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                            ),
                          ),
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(emailCtrl.text),
                            child: Text(
                              'Send Reset Link',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (result != null && result.isNotEmpty) {
                      try {
                        await AuthService().sendPasswordResetEmail(result);
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              content: AlertSuccess('Password reset email sent.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
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
                      } catch (e) {
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              content: AlertError('Failed to send reset email: $e'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
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
                    }
                  },
            child: Text(
              'Forgot Password?',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _login,
        style: ElevatedButton.styleFrom(
          padding: ResponsiveHelper.getAdaptivePadding(context),
        ),
        child: _loading
            ? SizedBox(
                width: ResponsiveHelper.getAdaptiveIconSize(context),
                height: ResponsiveHelper.getAdaptiveIconSize(context),
                child: const Loader(),
              )
            : Text(
                'Login',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
