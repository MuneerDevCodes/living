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
            shippingAddress: '', // Default empty address
            paymentMethod: '', // Default empty payment method
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
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                _buildRegisterButton(),
              ],
            ),
          );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        TextFormField(
          controller: _nameCtrl,
          decoration: InputDecoration(
            labelText: 'Username',
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
          validator: validateName,
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
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
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _register,
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
                'Register',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

