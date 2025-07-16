import 'package:flutter/material.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/services/notification_service.dart';
import 'package:living/services/data_export_service.dart';

import 'package:living/services/auth_helper.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final NotificationService _notificationService = NotificationService();
  final DataExportService _dataExportService = DataExportService();


  Map<String, bool> _notificationSettings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final notificationSettings = await _notificationService.getNotificationSettings();

      setState(() {
        _notificationSettings = notificationSettings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                  _buildSectionTitle('Notifications'),
                  _buildNotificationSettings(),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                  
                  _buildSectionTitle('Data Export'),
                  _buildDataExportSettings(),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                  
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

  Widget _buildNotificationSettings() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: Text('Enable Notifications'),
            subtitle: Text('Receive reminders and updates'),
            value: _notificationSettings['notifications_enabled'] ?? true,
            onChanged: (value) async {
              await _notificationService.updateNotificationSettings({
                'notifications_enabled': value,
              });
              setState(() {
                _notificationSettings['notifications_enabled'] = value;
              });
            },
          ),
          SwitchListTile(
            title: Text('Carbon Footprint Reminders'),
            subtitle: Text('Daily reminders to log activities'),
            value: _notificationSettings['carbon_footprint_reminders'] ?? true,
            onChanged: (value) async {
              await _notificationService.updateNotificationSettings({
                'carbon_footprint_reminders': value,
              });
              setState(() {
                _notificationSettings['carbon_footprint_reminders'] = value;
              });
            },
          ),
          SwitchListTile(
            title: Text('Waste Tracker Reminders'),
            subtitle: Text('Reminders to log waste reduction'),
            value: _notificationSettings['waste_tracker_reminders'] ?? true,
            onChanged: (value) async {
              await _notificationService.updateNotificationSettings({
                'waste_tracker_reminders': value,
              });
              setState(() {
                _notificationSettings['waste_tracker_reminders'] = value;
              });
            },
          ),
          SwitchListTile(
            title: Text('Challenge Reminders'),
            subtitle: Text('New challenge notifications'),
            value: _notificationSettings['challenge_reminders'] ?? true,
            onChanged: (value) async {
              await _notificationService.updateNotificationSettings({
                'challenge_reminders': value,
              });
              setState(() {
                _notificationSettings['challenge_reminders'] = value;
              });
            },
          ),
          SwitchListTile(
            title: Text('Weekly Reports'),
            subtitle: Text('Weekly progress summaries'),
            value: _notificationSettings['weekly_reports'] ?? true,
            onChanged: (value) async {
              await _notificationService.updateNotificationSettings({
                'weekly_reports': value,
              });
              setState(() {
                _notificationSettings['weekly_reports'] = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDataExportSettings() {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text('Export Carbon Footprint Data'),
            subtitle: Text('Download your carbon tracking data'),
            trailing: Icon(Icons.download),
            onTap: () => _showExportDialog('carbon_footprint'),
          ),
          ListTile(
            title: Text('Export Waste Tracker Data'),
            subtitle: Text('Download your waste reduction data'),
            trailing: Icon(Icons.download),
            onTap: () => _showExportDialog('waste_tracker'),
          ),
          ListTile(
            title: Text('Export All Data'),
            subtitle: Text('Download complete sustainability data'),
            trailing: Icon(Icons.download),
            onTap: () => _showExportDialog('all'),
          ),
        ],
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

  void _showExportDialog(String dataType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choose export format:'),
            SizedBox(height: 16),
            ListTile(
              title: Text('JSON'),
              subtitle: Text('Machine-readable format'),
              onTap: () {
                Navigator.pop(context);
                _exportData(dataType, 'json');
              },
            ),
            ListTile(
              title: Text('CSV'),
              subtitle: Text('Spreadsheet format'),
              onTap: () {
                Navigator.pop(context);
                _exportData(dataType, 'csv');
              },
            ),
            ListTile(
              title: Text('PDF'),
              subtitle: Text('Document format'),
              onTap: () {
                Navigator.pop(context);
                _exportData(dataType, 'pdf');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(String dataType, String format) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: 30));
    final endDate = now;

    try {
      switch (dataType) {
        case 'carbon_footprint':
          await _dataExportService.exportCarbonFootprintData(
            context,
            format: format,
            startDate: startDate,
            endDate: endDate,
          );
          break;
        case 'waste_tracker':
          await _dataExportService.exportWasteTrackerData(
            context,
            format: format,
            startDate: startDate,
            endDate: endDate,
          );
          break;
        case 'all':
          await _dataExportService.exportAllData(
            context,
            format: format,
            startDate: startDate,
            endDate: endDate,
          );
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
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