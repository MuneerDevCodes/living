import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:living/services/validate.dart';
import 'package:living/services/auth_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:living/models/user_model.dart' as app_user;
import 'package:living/services/user_dao.dart';
import 'package:living/widgets/alert_error.dart';
import 'package:living/widgets/loader.dart';

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
            // All other fields are nullable and default to null
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
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AlertError(
                    _error!,
                    onClose: () => setState(() => _error = null),
                  ),
                ),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: validateName,
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
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _register,
                child: const Text('Register'),
              ),
            ],
          ),
        );
  }
}

