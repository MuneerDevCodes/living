import 'package:flutter/material.dart';
import 'package:living/models/user_model.dart' as app_user;
import 'package:living/services/user_dao.dart';
import 'package:living/services/auth_helper.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/widgets/alert_error.dart';
import 'package:living/widgets/loader.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Only for EmailAuthProvider
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  static const String routeName = '/profile';

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
            ),
          ),
          content: TextField(
            controller: ctrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Current Password',
              labelStyle: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
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
              onPressed: () {
                result = ctrl.text;
                Navigator.of(context).pop();
              },
              child: Text(
                'Continue',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                ),
              ),
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
      await AuthService().sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent. Please check your inbox.'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = "Failed to send verification email: $e";
      });
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  Future<void> _updatePassword() async {
    if (_newPassCtrl.text.isEmpty) return;
    final currentPassword = await _promptPassword('Password Change');
    if (currentPassword == null) return;
    if (!await _reauthenticate(currentPassword)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AuthService().updatePassword(_newPassCtrl.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully')),
        );
        _newPassCtrl.clear();
      }
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: Loader()));
    }

    return Scaffold(
      drawer: Header.buildDrawer(context),
      body: Column(
        children: [
          const Header(),
          Expanded(
            child: SingleChildScrollView(
              padding: ResponsiveHelper.getAdaptivePadding(context),
              child: Container(
                constraints: ResponsiveHelper.getFlexibleConstraints(context),
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                    _buildProfileForm(),
                    if (_error != null) ...[
                      SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                      AlertError(_error!),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const Footer(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getAdaptiveBorderRadius(context),
        ),
      ),
      child: Padding(
        padding: ResponsiveHelper.getCardPadding(context),
        child: Column(
          children: [
            Icon(
              Icons.account_circle,
              size: ResponsiveHelper.getAdaptiveIconSize(context) * 3,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            Text(
              'Profile Settings',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 24),
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
            Text(
              'Manage your account information and preferences',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildSectionCard(
            'Personal Information',
            [
              _buildTextField(
                controller: _nameCtrl,
                label: 'Display Name',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          _buildSectionCard(
            'Email Settings',
            [
              _buildTextField(
                controller: _emailCtrl,
                label: 'Email Address',
                icon: Icons.email,
                enabled: false,
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
              Row(
                children: [
                  Icon(
                    _emailVerified ? Icons.verified : Icons.warning,
                    color: _emailVerified ? AppColors.success : AppColors.warning,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                  Expanded(
                    child: Text(
                      _emailVerified ? 'Email verified' : 'Email not verified',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        color: _emailVerified ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _updateEmail,
                      icon: Icon(
                        Icons.edit,
                        size: ResponsiveHelper.getAdaptiveIconSize(context),
                      ),
                      label: Text(
                        'Update Email',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _sendEmailVerification,
                      icon: Icon(
                        Icons.verified_user,
                        size: ResponsiveHelper.getAdaptiveIconSize(context),
                      ),
                      label: Text(
                        'Send Verification',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          _buildSectionCard(
            'Security',
            [
              _buildTextField(
                controller: _newPassCtrl,
                label: 'New Password',
                icon: Icons.lock,
                obscureText: true,
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _updatePassword,
                  icon: Icon(
                    Icons.security,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                  ),
                  label: Text(
                    'Update Password',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                padding: ResponsiveHelper.getAdaptivePadding(context),
              ),
              child: _saving
                  ? SizedBox(
                      width: ResponsiveHelper.getAdaptiveIconSize(context),
                      height: ResponsiveHelper.getAdaptiveIconSize(context),
                      child: const Loader(),
                    )
                  : Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getAdaptiveBorderRadius(context),
        ),
      ),
      child: Padding(
        padding: ResponsiveHelper.getCardPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          size: ResponsiveHelper.getAdaptiveIconSize(context),
        ),
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
    );
  }
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
