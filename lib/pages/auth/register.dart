import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:living/services/validate.dart';
import 'package:living/services/auth_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:living/models/user_model.dart' as app_user;
import 'package:living/services/user_dao.dart';
import 'package:living/widgets/alert_error.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  Future<void> _saveUserToPrefs(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', uid);
  }

  void _register() async {
    setState(() {
      _error = null;
    });
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _loading = true);
      try {
        final user = await AuthService().register(
          _emailCtrl.text,
          _passCtrl.text,
          _nameCtrl.text,
        );
        if (user != null) {
          // Create user object
          final userObj = app_user.User(
            uuid: user.uid,
            role: 'user', // Default role
            displayname: _nameCtrl.text,
          );

          // Save user using UserDao
          final userDao = UserDao();
          userDao.saveUser(userObj);

          await _saveUserToPrefs(user.uid);
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/profile');
          }
        }
      } on FirebaseAuthException catch (e) {
        setState(() => _error = e.message ?? "Registration failed");
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
                _buildRegisterButton(),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8),
                _buildTermsAndPrivacy(),
              ],
            ),
          );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        // Username field
        _buildUsernameField(),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8),
        // Email field
        _buildEmailField(),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8),
        // Password field
        _buildPasswordField(),
      ],
    );
  }

  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.person_outline,
              color: AppColors.primary,
              size: ResponsiveHelper.getAdaptiveIconSize(context) * 0.8,
            ),
            SizedBox(width: ResponsiveHelper.getAdaptiveGap(context) * 0.5),
            Text(
              'Full Name',
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
          controller: _nameCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Enter your full name',
            prefixIcon: Icon(
              Icons.person,
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
          validator: validateName,
        ),
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
            hintText: 'Create a strong password',
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
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
        // Password strength indicator
        _buildPasswordStrengthIndicator(),
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final password = _passCtrl.text;
    Color strengthColor = AppColors.secondaryText;
    String strengthText = 'Password strength';
    IconData strengthIcon = Icons.info_outline;

    if (password.isNotEmpty) {
      if (password.length >= 8 && 
          password.contains(RegExp(r'[A-Z]')) && 
          password.contains(RegExp(r'[a-z]')) && 
          password.contains(RegExp(r'[0-9]'))) {
        strengthColor = AppColors.success;
        strengthText = 'Strong password';
        strengthIcon = Icons.check_circle;
      } else if (password.length >= 6) {
        strengthColor = AppColors.warning;
        strengthText = 'Medium strength';
        strengthIcon = Icons.warning;
      } else {
        strengthColor = AppColors.error;
        strengthText = 'Weak password';
        strengthIcon = Icons.error;
      }
    }

    return Row(
      children: [
        Icon(
          strengthIcon,
          color: strengthColor,
          size: ResponsiveHelper.getAdaptiveIconSize(context) * 0.6,
        ),
        SizedBox(width: ResponsiveHelper.getAdaptiveGap(context) * 0.3),
        Text(
          strengthText,
          style: TextStyle(
            fontSize: ResponsiveHelper.getBodyFontSize(context) * 0.8,
            color: strengthColor,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      width: double.infinity,
      height: ResponsiveHelper.getButtonHeight(context),
      child: ElevatedButton(
        onPressed: _loading ? null : _register,
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
                    Icons.person_add,
                    size: ResponsiveHelper.getAdaptiveIconSize(context) * 0.8,
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveGap(context) * 0.5),
                  Text(
                    'Create Account',
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

  Widget _buildTermsAndPrivacy() {
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
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.primary,
            size: ResponsiveHelper.getAdaptiveIconSize(context) * 0.7,
          ),
          SizedBox(width: ResponsiveHelper.getAdaptiveGap(context) * 0.5),
          Expanded(
            child: Text(
              'By creating an account, you agree to our Terms of Service and Privacy Policy',
              style: TextStyle(
                fontSize: ResponsiveHelper.getBodyFontSize(context) * 0.8,
                color: AppColors.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

