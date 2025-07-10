import 'package:flutter/material.dart';
import 'package:living/models/user_model.dart' as app_user;
import 'package:living/services/user_dao.dart';
import 'package:living/services/auth_helper.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/widgets/alert_error.dart';
import 'package:living/widgets/loader.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      _userDao.updateUser(
        _userKey!,
        app_user.User(
          uuid: _uid!,
          role: _currentRole ?? 'user',
          displayname: _nameCtrl.text,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      }
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

  Future<void> _updatePassword() async {
    if (_newPassCtrl.text.isEmpty) return;
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

  void _showPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Update Password',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: _newPassCtrl,
          decoration: InputDecoration(
            labelText: 'New Password',
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updatePassword();
            },
            child: Text(
              'Update',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(child: Loader()),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: Header.buildDrawer(context),
      body: SafeArea(
        child: Column(
          children: [
            const Header(),
            Expanded(
              child: Padding(
                padding: ResponsiveHelper.getAdaptivePadding(context),
                child: Stack(
                  children: [
                    if (_error != null)
                      AlertError(
                        _error!,
                        onClose: () => setState(() => _error = null),
                      ),
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildProfileHeader(),
                          SizedBox(height: ResponsiveHelper.getSectionSpacing(context)),
                          _buildProfileForm(),
                          SizedBox(height: ResponsiveHelper.getSectionSpacing(context)),
                          _buildAccountActions(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Footer(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          children: [
            CircleAvatar(
              radius: ResponsiveHelper.getAdaptiveImageSize(context),
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.person,
                size: ResponsiveHelper.getAdaptiveIconSize(context) * 2,
                color: Colors.white,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            Text(
              _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'User',
              style: TextStyle(
                fontSize: ResponsiveHelper.getTitleFontSize(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
            Text(
              _email ?? 'No email',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                color: AppColors.secondaryText,
              ),
            ),
            if (_currentRole != null) ...[
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3,
                  vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.1,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3,
                  ),
                ),
                child: Text(
                  _currentRole!.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileForm() {
    return Card(
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile Information',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getSubtitleFontSize(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Display Name',
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: ResponsiveHelper.getAdaptivePadding(context),
                  ),
                  child: Text(
                    _saving ? 'Saving...' : 'Save Profile',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountActions() {
    return Card(
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Actions',
              style: TextStyle(
                fontSize: ResponsiveHelper.getSubtitleFontSize(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            if (ResponsiveHelper.isMobile(context))
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _updateEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        foregroundColor: Colors.white,
                        padding: ResponsiveHelper.getAdaptivePadding(context),
                      ),
                      child: Text(
                        'Update Email',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : () => _showPasswordDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.tertiary,
                        foregroundColor: Colors.white,
                        padding: ResponsiveHelper.getAdaptivePadding(context),
                      ),
                      child: Text(
                        'Update Password',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _updateEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        foregroundColor: Colors.white,
                        padding: ResponsiveHelper.getAdaptivePadding(context),
                      ),
                      child: Text(
                        'Update Email',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : () => _showPasswordDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.tertiary,
                        foregroundColor: Colors.white,
                        padding: ResponsiveHelper.getAdaptivePadding(context),
                      ),
                      child: Text(
                        'Update Password',
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
      ),
    );
  }
}
