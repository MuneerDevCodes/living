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
import 'package:living/style/theme.dart';

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
  bool _obscurePassword = true;
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
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 1.2),
                _buildLoginButton(),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8),
                _buildForgotPassword(),
              ],
            ),
          );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        // Email field with enhanced styling
        _buildEmailField(),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8),
        // Password field with enhanced styling
        _buildPasswordField(),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.email_outlined,
              color: AppColors.primary,
              size: ResponsiveHelper.getAdaptiveIconSize(context) * 0.8,
            ),
            SizedBox(width: ResponsiveHelper.getAdaptiveGap(context) * 0.5),
            Text(
              'Email Address',
              style: TextStyle(
                fontSize: ResponsiveHelper.getBodyFontSize(context) * 0.9,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Enter your email address',
            prefixIcon: Icon(
              Icons.email,
              color: AppColors.primary,
              size: ResponsiveHelper.getAdaptiveIconSize(context) * 0.7,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getAdaptiveBorderRadius(context),
              ),
              borderSide: BorderSide(color: AppColors.borderMedium),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getAdaptiveBorderRadius(context),
              ),
              borderSide: BorderSide(color: AppColors.borderMedium),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getAdaptiveBorderRadius(context),
              ),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: AppColors.surfaceBackground,
            contentPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.getAdaptiveSpacing(context),
              vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8,
            ),
          ),
          style: TextStyle(
            fontSize: ResponsiveHelper.getBodyFontSize(context),
            color: AppColors.primaryText,
          ),
          validator: validateEmail,
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lock_outline,
              color: AppColors.primary,
              size: ResponsiveHelper.getAdaptiveIconSize(context) * 0.8,
            ),
            SizedBox(width: ResponsiveHelper.getAdaptiveGap(context) * 0.5),
            Text(
              'Password',
              style: TextStyle(
                fontSize: ResponsiveHelper.getBodyFontSize(context) * 0.9,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
        TextFormField(
          controller: _passCtrl,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: 'Enter your password',
            prefixIcon: Icon(
              Icons.lock,
              color: AppColors.primary,
              size: ResponsiveHelper.getAdaptiveIconSize(context) * 0.7,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: AppColors.primary,
                size: ResponsiveHelper.getAdaptiveIconSize(context) * 0.7,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getAdaptiveBorderRadius(context),
              ),
              borderSide: BorderSide(color: AppColors.borderMedium),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getAdaptiveBorderRadius(context),
              ),
              borderSide: BorderSide(color: AppColors.borderMedium),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getAdaptiveBorderRadius(context),
              ),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: AppColors.surfaceBackground,
            contentPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.getAdaptiveSpacing(context),
              vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8,
            ),
          ),
          style: TextStyle(
            fontSize: ResponsiveHelper.getBodyFontSize(context),
            color: AppColors.primaryText,
          ),
          validator: validatePass,
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: ResponsiveHelper.getButtonHeight(context),
      child: ElevatedButton(
        onPressed: _loading ? null : _login,
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
        child: _loading
            ? SizedBox(
                width: ResponsiveHelper.getAdaptiveIconSize(context),
                height: ResponsiveHelper.getAdaptiveIconSize(context),
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.login,
                    size: ResponsiveHelper.getAdaptiveIconSize(context) * 0.8,
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveGap(context) * 0.5),
                  Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getBodyFontSize(context) * 1.1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Center(
      child: TextButton.icon(
        onPressed: _loading
            ? null
            : () async {
                final emailCtrl = TextEditingController(
                  text: _emailCtrl.text,
                );
                final result = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Row(
                      children: [
                        Icon(
                          Icons.lock_reset,
                          color: AppColors.primary,
                          size: ResponsiveHelper.getAdaptiveIconSize(context),
                        ),
                        SizedBox(width: ResponsiveHelper.getAdaptiveGap(context) * 0.5),
                        Text(
                          'Reset Password',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Enter your email address and we\'ll send you a link to reset your password.',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getBodyFontSize(context),
                            color: AppColors.secondaryText,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                        TextField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            hintText: 'Enter your email',
                            prefixIcon: Icon(
                              Icons.email,
                              color: AppColors.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                ResponsiveHelper.getAdaptiveBorderRadius(context),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(emailCtrl.text),
                        icon: Icon(
                          Icons.send,
                          size: ResponsiveHelper.getAdaptiveIconSize(context) * 0.7,
                        ),
                        label: Text(
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
                          content: AlertSuccess('Password reset email sent successfully!'),
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
        icon: Icon(
          Icons.help_outline,
          size: ResponsiveHelper.getAdaptiveIconSize(context) * 0.7,
          color: AppColors.primary,
        ),
        label: Text(
          'Forgot Password?',
          style: TextStyle(
            fontSize: ResponsiveHelper.getBodyFontSize(context) * 0.9,
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
