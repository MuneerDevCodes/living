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
import 'package:living/services/validate.dart';

/// ProfilePage displays and allows editing of the user's profile, using responsive and theme-driven design.
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

  // Comprehensive profile form controllers
  final _comprehensiveFormKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _addressLine1Ctrl = TextEditingController();
  final _addressLine2Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _zipCodeCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _shippingEmailCtrl = TextEditingController();
  final _paymentMethodCtrl = TextEditingController();
  final _easypaisaNumberCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();

  bool _saving = false;
  bool _loading = true;
  String? _error;
  String? _email;
  String? _uid;
  String? _userKey;
  String? _currentRole;
  app_user.User? _currentUser;
  String _selectedPaymentMethod = 'Easypaisa';

  final _userDao = UserDao();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _newPassCtrl.dispose();
    _nameCtrl.dispose();
    _fullNameCtrl.dispose();
    _addressLine1Ctrl.dispose();
    _addressLine2Ctrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _zipCodeCtrl.dispose();
    _countryCtrl.dispose();
    _phoneCtrl.dispose();
    _shippingEmailCtrl.dispose();
    _paymentMethodCtrl.dispose();
    _easypaisaNumberCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    super.dispose();
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
        _currentUser = u;
        _currentRole = u.role;
        _nameCtrl.text = u.displayname;
        _userKey = snap.key;

        // Load shipping info
        if (u.shippingInfo != null) {
          _fullNameCtrl.text = u.shippingInfo!.fullName;
          _addressLine1Ctrl.text = u.shippingInfo!.addressLine1;
          _addressLine2Ctrl.text = u.shippingInfo!.addressLine2 ?? '';
          _cityCtrl.text = u.shippingInfo!.city;
          _stateCtrl.text = u.shippingInfo!.state;
          _zipCodeCtrl.text = u.shippingInfo!.zipCode;
          _countryCtrl.text = u.shippingInfo!.country;
          _phoneCtrl.text = u.shippingInfo!.phone;
          _shippingEmailCtrl.text = u.shippingInfo!.email ?? '';
        }

        // Load payment info
        if (u.paymentInfo != null) {
          _easypaisaNumberCtrl.text = u.paymentInfo!.easypaisaNumber ?? '';
          _bankNameCtrl.text = u.paymentInfo!.bankName ?? '';
          _accountNumberCtrl.text = u.paymentInfo!.accountNumber ?? '';
          // Only set to valid dropdown values
          if (u.paymentMethod == 'Easypaisa' || u.paymentMethod == 'Bank Transfer') {
            _selectedPaymentMethod = u.paymentMethod!;
          } else {
            _selectedPaymentMethod = 'Easypaisa';
          }
        }
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

  Future<void> _saveComprehensiveProfile() async {
    if (!_comprehensiveFormKey.currentState!.validate() ||
        _uid == null ||
        _userKey == null) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // Create shipping info
      final shippingInfo = app_user.ShippingInfo(
        fullName: _fullNameCtrl.text,
        addressLine1: _addressLine1Ctrl.text,
        addressLine2: _addressLine2Ctrl.text.isNotEmpty ? _addressLine2Ctrl.text : null,
        city: _cityCtrl.text,
        state: _stateCtrl.text,
        zipCode: _zipCodeCtrl.text,
        country: _countryCtrl.text,
        phone: _phoneCtrl.text,
        email: _shippingEmailCtrl.text.isNotEmpty ? _shippingEmailCtrl.text : null,
      );

      // Create payment info based on selected method
      app_user.PaymentInfo? paymentInfo;
      String paymentMethodDisplay = _selectedPaymentMethod;

      switch (_selectedPaymentMethod) {
        case 'Easypaisa':
          if (_easypaisaNumberCtrl.text.isNotEmpty) {
            paymentInfo = app_user.PaymentInfo(
              easypaisaNumber: _easypaisaNumberCtrl.text,
            );
            paymentMethodDisplay = 'Easypaisa •••• ${_easypaisaNumberCtrl.text.substring(_easypaisaNumberCtrl.text.length - 4)}';
          }
          break;
        case 'Bank Transfer':
          if (_bankNameCtrl.text.isNotEmpty && _accountNumberCtrl.text.isNotEmpty) {
            paymentInfo = app_user.PaymentInfo(
              bankName: _bankNameCtrl.text,
              accountNumber: _accountNumberCtrl.text,
            );
            paymentMethodDisplay = '${_bankNameCtrl.text} •••• ${_accountNumberCtrl.text.substring(_accountNumberCtrl.text.length - 4)}';
          }
          break;
      }

      // Update user with comprehensive information
      _userDao.updateUser(
        _userKey!,
        app_user.User(
          uuid: _uid!,
          role: _currentRole ?? 'user',
          displayname: _nameCtrl.text,
          shippingInfo: shippingInfo,
          paymentInfo: paymentInfo,
          paymentMethod: paymentMethodDisplay,
        ),
      );
      
      setState(() {
        _currentUser = _currentUser?.copyWith(
          shippingInfo: shippingInfo,
          paymentInfo: paymentInfo,
          paymentMethod: paymentMethodDisplay,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile information updated successfully'),
            backgroundColor: AppColors.success,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = "Failed to save profile: $e";
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
          SnackBar(
            content: Text(
              'Verification email sent to the new email. Please verify to complete the update.',
            ),
            backgroundColor: AppColors.info,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
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
          SnackBar(
            content: Text('Password updated successfully'),
            backgroundColor: AppColors.success,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
            ),
          ),
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

  /// Build method for the profile page, using only ResponsiveHelper and AppTheme/AppColors.
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(child: Loader()),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
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
                          _buildComprehensiveProfileForm(),
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

  Widget _buildComprehensiveProfileForm() {
    return Card(
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Form(
          key: _comprehensiveFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complete Profile Information',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getSubtitleFontSize(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              
              // Basic Profile Information
              Text(
                'Basic Information',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
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
              SizedBox(height: ResponsiveHelper.getSectionSpacing(context)),
              
              // Shipping Information
              Text(
                'Shipping Information',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
              TextFormField(
                controller: _fullNameCtrl,
                decoration: InputDecoration(
                  labelText: 'Full Name',
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
                controller: _addressLine1Ctrl,
                decoration: InputDecoration(
                  labelText: 'Address Line 1',
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
                validator: validateAddressLine1,
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              TextFormField(
                controller: _addressLine2Ctrl,
                decoration: InputDecoration(
                  labelText: 'Address Line 2 (Optional)',
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
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityCtrl,
                      decoration: InputDecoration(
                        labelText: 'City',
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
                      validator: validateCity,
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
                  Expanded(
                    child: TextFormField(
                      controller: _stateCtrl,
                      decoration: InputDecoration(
                        labelText: 'State',
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
                      validator: validateState,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _zipCodeCtrl,
                      decoration: InputDecoration(
                        labelText: 'Zip Code',
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
                      validator: validateZipCode,
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
                  Expanded(
                    child: TextFormField(
                      controller: _countryCtrl,
                      decoration: InputDecoration(
                        labelText: 'Country',
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
                      validator: validateCountry,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneCtrl,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
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
                      validator: validatePhone,
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
                  Expanded(
                    child: TextFormField(
                      controller: _shippingEmailCtrl,
                      decoration: InputDecoration(
                        labelText: 'Shipping Email (Optional)',
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
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getSectionSpacing(context)),
              
              // Payment Information
              Text(
                'Payment Information',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
              
              // Payment Method Selection
              DropdownButtonFormField<String>(
                value: _selectedPaymentMethod,
                decoration: InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.6,
                    ),
                  ),
                  labelStyle: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  ),
                ),
                items: [
                  'Easypaisa',
                  'Bank Transfer',
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedPaymentMethod = newValue!;
                  });
                },
                validator: validatePaymentMethod,
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              
              // Conditional Payment Fields
              if (_selectedPaymentMethod == 'Easypaisa') ...[
                TextFormField(
                  controller: _easypaisaNumberCtrl,
                  decoration: InputDecoration(
                    labelText: 'Easypaisa Number',
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
                  validator: validatePhone,
                ),
              ] else if (_selectedPaymentMethod == 'Bank Transfer') ...[
                TextFormField(
                  controller: _bankNameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Bank Name',
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
                  controller: _accountNumberCtrl,
                  decoration: InputDecoration(
                    labelText: 'Account Number',
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
                    if (value == null || value.isEmpty) return "Account number is required";
                    final regExp = RegExp(r'^\d+$');
                    return regExp.hasMatch(value) ? null : "Please enter a valid account number";
                  },
                ),
              ],
              
              SizedBox(height: ResponsiveHelper.getSectionSpacing(context)),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _saveComprehensiveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: ResponsiveHelper.getAdaptivePadding(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.6,
                      ),
                    ),
                  ),
                  icon: _saving 
                    ? SizedBox(
                        width: ResponsiveHelper.getAdaptiveIconSize(context),
                        height: ResponsiveHelper.getAdaptiveIconSize(context),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        Icons.save,
                        size: ResponsiveHelper.getAdaptiveIconSize(context),
                      ),
                  label: Text(
                    _saving ? 'Saving...' : 'Save Complete Profile',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                      fontWeight: FontWeight.w600,
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
