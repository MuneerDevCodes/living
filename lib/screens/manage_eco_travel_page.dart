import 'package:flutter/material.dart';
import 'package:living/models/eco_travel_model.dart';
import 'package:living/services/eco_travel_dao.dart';
import 'package:living/services/admin_service.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/widgets/alert_error.dart';
import 'package:living/widgets/alert_success.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';
import 'package:intl/intl.dart';

/// ManageEcoTravelPage allows admins to approve or reject pending eco-travel suggestions
class ManageEcoTravelPage extends StatefulWidget {
  const ManageEcoTravelPage({super.key});

  @override
  State<ManageEcoTravelPage> createState() => _ManageEcoTravelPageState();
}

class _ManageEcoTravelPageState extends State<ManageEcoTravelPage> {
  List<EcoTravelSuggestion> pendingSuggestions = [];
  bool isLoading = true;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _initAdminAndLoad();
  }

  Future<void> _initAdminAndLoad() async {
    final admin = await AdminService().isAdmin();
    if (mounted) {
      setState(() {
        isAdmin = admin;
      });
    }
    if (admin) {
      await _loadPendingSuggestions();
    }
  }

  Future<void> _loadPendingSuggestions() async {
    try {
      setState(() => isLoading = true);
      final suggestions = await EcoTravelDAO.getPendingSuggestions();
      if (mounted) {
        setState(() {
          pendingSuggestions = suggestions;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        showDialog(
          context: context,
          builder: (context) => AlertError('Failed to load pending suggestions: $e'),
        );
      }
    }
  }

  Future<void> _approveSuggestion(EcoTravelSuggestion suggestion) async {
    try {
      await EcoTravelDAO.approveSuggestion(suggestion.key);
      await _loadPendingSuggestions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Suggestion approved successfully!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertError('Failed to approve suggestion: $e'),
        );
      }
    }
  }

  Future<void> _rejectSuggestion(EcoTravelSuggestion suggestion) async {
    try {
      await EcoTravelDAO.rejectSuggestion(suggestion.key);
      await _loadPendingSuggestions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Suggestion rejected successfully!'),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertError('Failed to reject suggestion: $e'),
        );
      }
    }
  }

  void _showSuggestionDetail(EcoTravelSuggestion suggestion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          suggestion.title,
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                suggestion.description,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  color: AppColors.secondaryText,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              
              // Creator Info
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                    color: AppColors.primary,
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                  Text(
                    'By: ${suggestion.createdByName}',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              
              // Created Date
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                    color: AppColors.mutedText,
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                  Text(
                    'Submitted: ${DateFormat('MMM dd, yyyy').format(suggestion.createdAt)}',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              
              // Location
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                    color: AppColors.info,
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                  Text(
                    suggestion.location,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      color: AppColors.info,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              
              // Category
              Row(
                children: [
                  Icon(
                    Icons.category,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                    color: AppColors.mutedText,
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                  Text(
                    'Category: ${suggestion.category}',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              
              // Carbon Impact
              Row(
                children: [
                  Icon(
                    suggestion.carbonImpact < 0 ? Icons.trending_down : Icons.cloud,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                    color: suggestion.carbonImpact < 0 ? AppColors.success : AppColors.info,
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                  Text(
                    'Carbon Impact: ${suggestion.carbonImpact.toStringAsFixed(1)} ${suggestion.carbonUnit}',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      color: suggestion.carbonImpact < 0 ? AppColors.success : AppColors.info,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 1.5),
              
              // Benefits Section
              if (suggestion.benefits.isNotEmpty) ...[
                Text(
                  'Benefits:',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                ...suggestion.benefits.map((benefit) => Padding(
                  padding: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: ResponsiveHelper.getAdaptiveIconSize(context),
                        color: AppColors.success,
                      ),
                      SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                      Expanded(
                        child: Text(
                          benefit,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              ],
              
              // Tips Section
              if (suggestion.tips.isNotEmpty) ...[
                Text(
                  'Tips:',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                ...suggestion.tips.map((tip) => Padding(
                  padding: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb,
                        size: ResponsiveHelper.getAdaptiveIconSize(context),
                        color: AppColors.warning,
                      ),
                      SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                      Expanded(
                        child: Text(
                          tip,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              _confirmRejectSuggestion(suggestion);
            },
            child: Text(
              'Reject',
              style: TextStyle(
                color: AppColors.white,
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () {
              Navigator.pop(context);
              _confirmApproveSuggestion(suggestion);
            },
            child: Text(
              'Approve',
              style: TextStyle(
                color: AppColors.white,
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmApproveSuggestion(EcoTravelSuggestion suggestion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Approve Suggestion'),
        content: Text('Are you sure you want to approve "${suggestion.title}"? This will make it visible to all users.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () {
              Navigator.pop(context);
              _approveSuggestion(suggestion);
            },
            child: Text('Approve', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmRejectSuggestion(EcoTravelSuggestion suggestion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Suggestion'),
        content: Text('Are you sure you want to reject "${suggestion.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              _rejectSuggestion(suggestion);
            },
            child: Text('Reject', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.background,
        drawer: Header.buildDrawer(context),
        body: Column(
          children: [
            const Header(),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      size: ResponsiveHelper.getAdaptiveIconSize(context) * 3,
                      color: AppColors.error,
                    ),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                    Text(
                      'Access Denied',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 24),
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                    Text(
                      'You need admin privileges to access this page.',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                        color: AppColors.secondaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            Footer(),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: Header.buildDrawer(context),
      body: Column(
        children: [
          const Header(),
          Expanded(
            child: Stack(
              children: [
                if (isLoading) const Positioned.fill(child: Loader()),
                Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: _buildSuggestionsList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Footer(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pending Eco-Travel Suggestions',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 24),
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
          Text(
            'Review and approve or reject user-submitted eco-travel suggestions',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
              color: AppColors.secondaryText,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          Container(
            padding: ResponsiveHelper.getAdaptivePadding(context),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getAdaptiveBorderRadius(context),
              ),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.pending_actions,
                  color: AppColors.warning,
                  size: ResponsiveHelper.getAdaptiveIconSize(context),
                ),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                Expanded(
                  child: Text(
                    '${pendingSuggestions.length} suggestion${pendingSuggestions.length != 1 ? 's' : ''} pending approval',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    if (pendingSuggestions.isEmpty) {
      return Container(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                size: ResponsiveHelper.getAdaptiveIconSize(context) * 3,
                color: AppColors.success,
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Text(
                'No Pending Suggestions',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 20),
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Text(
                'All eco-travel suggestions have been reviewed.',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      itemCount: pendingSuggestions.length,
      itemBuilder: (context, index) {
        final suggestion = pendingSuggestions[index];
        return _buildSuggestionCard(suggestion);
      },
    );
  }

  Widget _buildSuggestionCard(EcoTravelSuggestion suggestion) {
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context)),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getAdaptiveBorderRadius(context),
        ),
      ),
      child: InkWell(
        onTap: () => _showSuggestionDetail(suggestion),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getAdaptiveBorderRadius(context),
        ),
        child: Padding(
          padding: ResponsiveHelper.getAdaptivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      suggestion.title,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3,
                      vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3,
                      ),
                    ),
                    child: Text(
                      'PENDING',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
              Text(
                suggestion.description,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  color: AppColors.secondaryText,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                    color: AppColors.primary,
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                  Text(
                    suggestion.createdByName,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.schedule,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                    color: AppColors.mutedText,
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                  Text(
                    DateFormat('MMM dd').format(suggestion.createdAt),
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                    color: AppColors.info,
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                  Expanded(
                    child: Text(
                      suggestion.location,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                        color: AppColors.info,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3,
                      vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3,
                      ),
                    ),
                    child: Text(
                      suggestion.category,
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8,
                      ),
                    ),
                    onPressed: () => _confirmRejectSuggestion(suggestion),
                    child: Text(
                      'Reject',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8,
                      ),
                    ),
                    onPressed: () => _confirmApproveSuggestion(suggestion),
                    child: Text(
                      'Approve',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 