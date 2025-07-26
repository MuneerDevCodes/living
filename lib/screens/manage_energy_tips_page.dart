import 'package:flutter/material.dart';
import 'package:living/services/energy_tip_dao.dart';
import 'package:living/models/energy_tip_model.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';
import 'package:living/services/admin_service.dart';

class ManageEnergyTipsPage extends StatefulWidget {
  const ManageEnergyTipsPage({super.key});

  @override
  State<ManageEnergyTipsPage> createState() => _ManageEnergyTipsPageState();
}

class _ManageEnergyTipsPageState extends State<ManageEnergyTipsPage> {
  List<EnergyTip> pendingTips = [];
  bool isLoading = true;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAndLoad();
  }

  Future<void> _checkAdminAndLoad() async {
    final admin = await AdminService().isAdmin();
    setState(() => isAdmin = admin);
    if (admin) {
      await _loadPendingTips();
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadPendingTips() async {
    setState(() => isLoading = true);
    try {
      pendingTips = await EnergyTipDAO.getPendingEnergyTips();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load pending energy tips: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _approveTip(String key) async {
    await EnergyTipDAO.approveEnergyTip(key);
    await _loadPendingTips();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Energy tip approved!'), backgroundColor: AppColors.success),
    );
  }

  Future<void> _rejectTip(String key) async {
    await EnergyTipDAO.rejectEnergyTip(key);
    await _loadPendingTips();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Energy tip rejected.'), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: Loader()));
    }
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
                    Icon(Icons.admin_panel_settings, size: ResponsiveHelper.getAdaptiveIconSize(context) * 3, color: AppColors.error),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                    Text('Access Denied', style: TextStyle(fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 20), fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                    Text('You need admin privileges to access this page.', style: TextStyle(fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14), color: AppColors.secondaryText), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
            const Footer(),
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
            child: RefreshIndicator(
              onRefresh: _loadPendingTips,
              child: pendingTips.isEmpty
                  ? Center(child: Text('No pending energy tips.', style: TextStyle(fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16), color: AppColors.secondaryText)))
                  : ListView.builder(
                      padding: ResponsiveHelper.getAdaptivePadding(context),
                      itemCount: pendingTips.length,
                      itemBuilder: (context, index) {
                        final tip = pendingTips[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context)),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
                          ),
                          child: Padding(
                            padding: ResponsiveHelper.getAdaptivePadding(context),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tip.title, style: TextStyle(fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16), fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                                Text(tip.description, style: TextStyle(fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14), color: AppColors.secondaryText)),
                                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _approveTip(tip.key),
                                      icon: Icon(Icons.check, color: AppColors.white),
                                      label: Text('Approve'),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                                    ),
                                    SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
                                    ElevatedButton.icon(
                                      onPressed: () => _rejectTip(tip.key),
                                      icon: Icon(Icons.close, color: AppColors.white),
                                      label: Text('Reject'),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          const Footer(),
        ],
      ),
    );
  }
} 