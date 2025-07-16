import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:living/services/auth_helper.dart';
import 'package:living/style/theme.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Notification types
  static const String _carbonFootprintReminder = 'carbon_footprint_reminder';
  static const String _wasteTrackerReminder = 'waste_tracker_reminder';
  static const String _challengeReminder = 'challenge_reminder';
  static const String _goalReminder = 'goal_reminder';
  static const String _weeklyReport = 'weekly_report';

  // Check if user has logged activity today
  Future<bool> _hasLoggedActivityToday(String activityType) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = AuthService.getCurrentUserId();
    if (userId == null) return false;
    
    final lastLoggedKey = '${userId}_${activityType}_last_logged';
    final lastLogged = prefs.getString(lastLoggedKey);
    
    if (lastLogged == null) return false;
    
    final lastLoggedDate = DateTime.parse(lastLogged);
    final today = DateTime.now();
    
    return lastLoggedDate.year == today.year &&
           lastLoggedDate.month == today.month &&
           lastLoggedDate.day == today.day;
  }

  // Mark activity as logged today
  Future<void> _markActivityLogged(String activityType) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = AuthService.getCurrentUserId();
    if (userId == null) return;
    
    final lastLoggedKey = '${userId}_${activityType}_last_logged';
    await prefs.setString(lastLoggedKey, DateTime.now().toIso8601String());
  }

  // Check if notifications are enabled
  Future<bool> _areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  // Show carbon footprint reminder
  Future<void> showCarbonFootprintReminder(BuildContext context) async {
    if (!await _areNotificationsEnabled()) return;
    if (await _hasLoggedActivityToday(_carbonFootprintReminder)) return;

    _showNotificationDialog(
      context,
      'Track Your Carbon Footprint',
      'Don\'t forget to log your daily activities! Track your carbon footprint to see your environmental impact.',
      Icons.cloud,
      AppColors.info,
      () {
        Navigator.pushNamed(context, '/carbon-footprint');
        _markActivityLogged(_carbonFootprintReminder);
      },
    );
  }

  // Show waste tracker reminder
  Future<void> showWasteTrackerReminder(BuildContext context) async {
    if (!await _areNotificationsEnabled()) return;
    if (await _hasLoggedActivityToday(_wasteTrackerReminder)) return;

    _showNotificationDialog(
      context,
      'Track Your Waste',
      'Remember to log your waste reduction efforts! Monitor your progress and stay on track with your goals.',
      Icons.recycling,
      AppColors.success,
      () {
        Navigator.pushNamed(context, '/waste-tracker');
        _markActivityLogged(_wasteTrackerReminder);
      },
    );
  }

  // Show challenge reminder
  Future<void> showChallengeReminder(BuildContext context) async {
    if (!await _areNotificationsEnabled()) return;
    if (await _hasLoggedActivityToday(_challengeReminder)) return;

    _showNotificationDialog(
      context,
      'Join a Challenge',
      'New sustainability challenges are available! Participate to earn points and make a positive impact.',
      Icons.emoji_events,
      AppColors.warning,
      () {
        Navigator.pushNamed(context, '/challenges');
        _markActivityLogged(_challengeReminder);
      },
    );
  }

  // Show goal reminder
  Future<void> showGoalReminder(BuildContext context, String goalType, String goalName) async {
    if (!await _areNotificationsEnabled()) return;

    _showNotificationDialog(
      context,
      'Goal Reminder',
      'You\'re making great progress on your $goalName goal! Keep up the good work.',
      Icons.flag,
      AppColors.primary,
      () {
        Navigator.pushNamed(context, '/progress-dashboard');
      },
    );
  }

  // Show weekly report
  Future<void> showWeeklyReport(BuildContext context, Map<String, dynamic> reportData) async {
    if (!await _areNotificationsEnabled()) return;

    _showNotificationDialog(
      context,
      'Weekly Sustainability Report',
      'Your weekly summary is ready! See your progress and achievements.',
      Icons.analytics,
      AppColors.secondary,
      () {
        Navigator.pushNamed(context, '/progress-dashboard');
      },
    );
  }

  // Show notification dialog
  void _showNotificationDialog(
    BuildContext context,
    String title,
    String message,
    IconData icon,
    Color color,
    VoidCallback onAction,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onAction();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
            ),
            child: Text('Take Action'),
          ),
        ],
      ),
    );
  }

  // Schedule daily reminders
  Future<void> scheduleDailyReminders() async {
    // This would integrate with a proper notification system
    // For now, we'll use in-app reminders
    await _setReminderPreferences();
  }

  // Set reminder preferences
  Future<void> _setReminderPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('carbon_footprint_reminders', true);
    await prefs.setBool('waste_tracker_reminders', true);
    await prefs.setBool('challenge_reminders', true);
    await prefs.setBool('weekly_reports', true);
  }

  // Check and show appropriate reminders
  Future<void> checkAndShowReminders(BuildContext context) async {
    if (!await _areNotificationsEnabled()) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastReminderDate = prefs.getString('last_reminder_date');
    
    if (lastReminderDate != null) {
      final lastDate = DateTime.parse(lastReminderDate);
      if (now.difference(lastDate).inHours < 12) return; // Don't show too frequently
    }

    // Show reminders based on time of day and user activity
    final hour = now.hour;
    
    if (hour >= 9 && hour <= 11) {
      // Morning reminder
      await showCarbonFootprintReminder(context);
    } else if (hour >= 17 && hour <= 19) {
      // Evening reminder
      await showWasteTrackerReminder(context);
    } else if (hour >= 20 && hour <= 22) {
      // Night reminder
      await showChallengeReminder(context);
    }

    await prefs.setString('last_reminder_date', now.toIso8601String());
  }

  // Get notification settings
  Future<Map<String, bool>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'notifications_enabled': prefs.getBool('notifications_enabled') ?? true,
      'carbon_footprint_reminders': prefs.getBool('carbon_footprint_reminders') ?? true,
      'waste_tracker_reminders': prefs.getBool('waste_tracker_reminders') ?? true,
      'challenge_reminders': prefs.getBool('challenge_reminders') ?? true,
      'weekly_reports': prefs.getBool('weekly_reports') ?? true,
    };
  }

  // Update notification settings
  Future<void> updateNotificationSettings(Map<String, bool> settings) async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in settings.entries) {
      await prefs.setBool(entry.key, entry.value);
    }
  }
} 