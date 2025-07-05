import 'package:flutter/material.dart';
import 'package:living/models/user_model.dart' as app_user;
import 'package:living/services/user_dao.dart';
import 'package:living/services/auth_helper.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/widgets/alert_error.dart';
import 'package:living/widgets/loader.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Only for EmailAuthProvider

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  static const String routeName = '/profile';

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _shippingCtrl = TextEditingController();
  final _paymentCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _authService = AuthService();
  bool _emailVerified = false;

  bool _saving = false;
  bool _loading = true;
  String? _error;
  String? _email;
  String? _uid;
  String? _userKey;
  String? _currentRole;

  final _userDao = UserDao();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() {
      _loading = true;
    });
    try {
      final user = AuthService().currentUser;
      _email = user?.email;
      _uid = user?.uid;
      _emailCtrl.text = _email ?? '';
      _emailVerified = user?.emailVerified ?? false;
      final snapshot =
          await _userDao.getUserList().orderByChild('uuid').equalTo(_uid).get();
      if (snapshot.exists && snapshot.children.isNotEmpty) {
        final snap = snapshot.children.first;
        final u = app_user.User.fromJson(snap.value as Map<dynamic, dynamic>);
       
        _currentRole = u.role;
        
        _nameCtrl.text = u.displayname;
        _userKey = snap.key;
      }
    } catch (e) {
      _error = "Failed to load user: $e";
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() ||
        _uid == null ||
        _userKey == null) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // Only update username in database, not in Firebase Auth
      _userDao.updateUser(
        _userKey!,
        app_user.User(
          uuid: _uid!,
          role: _currentRole ?? 'user',
          
         
          displayname: _nameCtrl.text, // update username in DB only
        ),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (e) {
      setState(() {
        _error = "Failed to save: $e";
      });
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  // Helper to prompt for password using AppPopup
  Future<String?> _promptPassword(String action) async {
    final ctrl = TextEditingController();
    String? result;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Confirm $action',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: ctrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Current Password'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                result = ctrl.text;
                Navigator.of(context).pop();
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
    return result;
  }

  Future<bool> _reauthenticate(String currentPassword) async {
    final user = AuthService().currentUser;
    if (user == null || user.email == null) return false;
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    try {
      await user.reauthenticateWithCredential(cred);
      return true;
    } catch (_) {
      setState(() {
        _error = "Current password is incorrect";
      });
      return false;
    }
  }

  Future<void> _updateEmail() async {
    if (_emailCtrl.text.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AuthService().updateEmail(_emailCtrl.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Verification email sent to the new email. Please verify to complete the update.',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = "Failed to update email: $e";
      });
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  Future<void> _sendEmailVerification() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _authService.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent')),
        );
      }
    } catch (e) {
      setState(() {
        _error = "Failed to send verification: $e";
      });
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  Future<void> _updatePassword() async {
    if (_newPassCtrl.text.isEmpty) return;
    final password = await _promptPassword('Password Update');
    if (password == null || password.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    if (!await _reauthenticate(password)) {
      setState(() => _saving = false);
      return;
    }
    try {
      await _authService.updatePassword(_newPassCtrl.text);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Password updated')));
      }
      _newPassCtrl.clear();
    } catch (e) {
      setState(() {
        _error = "Failed to update password: $e";
      });
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  Future<void> _deleteAccount() async {
    final password = await _promptPassword('Account Deletion');
    if (password == null || password.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final user = AuthService().currentUser;
      if (user == null || user.email == null) throw Exception("No user found");
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);
      await _authService.deleteCurrentUser();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/logout');
      }
    } catch (e) {
      setState(() {
        _error = "Failed to delete account: $e";
      });
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  @override
  void dispose() {
    _shippingCtrl.dispose();
    _paymentCtrl.dispose();
    _emailCtrl.dispose();
    _newPassCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
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
              child:
                  _loading
                      ? const Loader()
                      : SingleChildScrollView(
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 32,
                          ),
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Profile Information',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextFormField(
                                    controller: _nameCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Username',
                                      prefixIcon: Icon(Icons.person),
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: validateName,
                                  ),
                                  const SizedBox(height: 16),
                                  if (_error != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: AlertError(
                                        _error!,
                                        onClose:
                                            () => setState(() => _error = null),
                                      ),
                                    ),
                                  TextFormField(
                                    controller: _shippingCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Shipping Address',
                                      prefixIcon: Icon(Icons.local_shipping),
                                      border: OutlineInputBorder(),
                                    ),
                                    validator:
                                        (v) =>
                                            v == null || v.isEmpty
                                                ? 'Enter shipping address'
                                                : null,
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                    value:
                                        _paymentCtrl.text.isNotEmpty
                                            ? _paymentCtrl.text
                                            : null,
                                    decoration: const InputDecoration(
                                      labelText: 'Payment Method',
                                      prefixIcon: Icon(Icons.credit_card),
                                      border: OutlineInputBorder(),
                                    ),
                                    items: [
                                      _dropdownItem(
                                        'Credit Card',
                                        Icons.credit_card,
                                      ),
                                      _dropdownItem(
                                        'PayPal',
                                        Icons.account_balance_wallet,
                                      ),
                                      _dropdownItem(
                                        'Google Pay',
                                        Icons.account_balance,
                                      ),
                                      _dropdownItem(
                                        'Cash on Delivery',
                                        Icons.money,
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) _paymentCtrl.text = val;
                                    },
                                    validator:
                                        (v) =>
                                            v == null || v.isEmpty
                                                ? 'Select payment method'
                                                : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _emailCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'New Email',
                                      prefixIcon: Icon(Icons.email),
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      ElevatedButton(
                                        onPressed:
                                            _saving ? null : _updateEmail,
                                        child: const Text('Update Email'),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed:
                                            _saving
                                                ? null
                                                : _sendEmailVerification,
                                        child: const Text('Send Verification'),
                                      ),
                                      const SizedBox(width: 8),
                                      Tooltip(
                                        message: _emailVerified ? "Email Verified" : "Email Not Verified",
                                        child: Icon(
                                          _emailVerified
                                              ? Icons.verified
                                              : Icons.error_outline,
                                          color:
                                              _emailVerified
                                                  ? Colors.green
                                                  : Colors.red,
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _newPassCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'New Password',
                                      prefixIcon: Icon(Icons.lock),
                                      border: OutlineInputBorder(),
                                    ),
                                    obscureText: true,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      ElevatedButton(
                                        onPressed:
                                            _saving ? null : _updatePassword,
                                        child: const Text('Update Password'),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed:
                                            _saving
                                                ? null
                                                : () async {
                                                  if ((_email ?? '').isEmpty) {
                                                    return;
                                                  }
                                                  try {
                                                    await _authService
                                                        .sendPasswordResetEmail(
                                                          _email!,
                                                        );
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Password reset email sent.',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Failed to send reset email: $e',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                        child: const Text('Forgotten Password'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      icon:
                                          _saving
                                              ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: Loader(),
                                              )
                                              : const Icon(Icons.save),
                                      label: Text(
                                        _saving ? 'Saving...' : 'Save',
                                      ),
                                      onPressed: _saving ? null : _saveProfile,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.logout),
                                        label: const Text('Logout'),
                                        onPressed: () {
                                          Navigator.pushReplacementNamed(
                                            context,
                                            '/logout',
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.delete_forever),
                                        label: const Text('Delete Account'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed:
                                            _saving ? null : _deleteAccount,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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

// Helper for dropdown items
DropdownMenuItem<String> _dropdownItem(String label, IconData icon) {
  return DropdownMenuItem(
    value: label,
    child: Row(
      children: [
        Icon(icon, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Text(label),
      ],
    ),
  );
}

// Name validation
String? validateName(String? value) {
  if (value == null || value.isEmpty) {
    return 'Enter your name';
  }
  if (value.length < 3) {
    return 'Name must be at least 3 characters';
  }
  return null;
}
