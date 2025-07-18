import 'package:flutter/material.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/services/auth_helper.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Header.buildDrawer(context),
      body: Column(
        children: [
          const Header(),
          Expanded(
            child: SingleChildScrollView(
              padding: ResponsiveHelper.getAdaptivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Account'),
                  _buildAccountSettings(),
                ],
              ),
            ),
          ),
          Footer(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: ResponsiveHelper.getAdaptiveSpacing(context),
        top: ResponsiveHelper.getAdaptiveSpacing(context) * 1.5,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: ResponsiveHelper.getSubtitleFontSize(context),
          fontWeight: FontWeight.bold,
          color: AppColors.primaryText,
        ),
      ),
    );
  }

  Widget _buildAccountSettings() {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text('Profile'),
            subtitle: Text('Manage your account information'),
            trailing: Icon(Icons.person),
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),
          ListTile(
            title: Text('Privacy Policy'),
            subtitle: Text('Read our privacy policy'),
            trailing: Icon(Icons.privacy_tip),
            onTap: () => _showPrivacyPolicy(),
          ),
          ListTile(
            title: Text('Terms of Service'),
            subtitle: Text('Read our terms of service'),
            trailing: Icon(Icons.description),
            onTap: () => _showTermsOfService(),
          ),
          ListTile(
            title: Text('Logout'),
            subtitle: Text('Sign out of your account'),
            trailing: Icon(Icons.logout),
            onTap: () => Navigator.pushNamed(context, '/logout'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Privacy Policy'),
        content: Text('Our privacy policy will be displayed here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Terms of Service'),
        content: Text('Our terms of service will be displayed here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
} 