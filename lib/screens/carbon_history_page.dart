import 'package:flutter/material.dart';
import 'package:living/models/carbon_footprint_model.dart';
import 'package:living/services/carbon_footprint_dao.dart';
import 'package:living/services/auth_helper.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/widgets/alert_error.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';
import 'package:intl/intl.dart';

/// CarbonHistoryPage displays the user's carbon footprint history, using responsive and theme-driven design.
class CarbonHistoryPage extends StatefulWidget {
  const CarbonHistoryPage({super.key});

  @override
  State<CarbonHistoryPage> createState() => _CarbonHistoryPageState();
}

class _CarbonHistoryPageState extends State<CarbonHistoryPage> {
  List<CarbonFootprintEntry> entries = [];
  List<CarbonFootprintEntry> filteredEntries = [];
  bool isLoading = true;
  String? userId;
  String selectedCategory = 'All';
  String selectedTimeRange = 'All Time';
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);
      userId = AuthService.getCurrentUserId();
      if (userId != null) {
        entries = await CarbonFootprintDAO.getUserEntries(userId!);
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertError('Failed to load data: $e'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _applyFilters() {
    filteredEntries = List.from(entries);

    // Apply category filter
    if (selectedCategory != 'All') {
      filteredEntries = filteredEntries.where((entry) => entry.category == selectedCategory).toList();
    }

    // Apply time range filter
    if (selectedTimeRange != 'All Time') {
      final now = DateTime.now();
      DateTime filterStartDate = now.subtract(Duration(days: 30)); // Default value

      switch (selectedTimeRange) {
        case 'Today':
          filterStartDate = DateTime(now.year, now.month, now.day);
          break;
        case 'This Week':
          filterStartDate = now.subtract(Duration(days: now.weekday - 1));
          break;
        case 'This Month':
          filterStartDate = DateTime(now.year, now.month, 1);
          break;
        case 'Last 30 Days':
          filterStartDate = now.subtract(Duration(days: 30));
          break;
        case 'Last 90 Days':
          filterStartDate = now.subtract(Duration(days: 90));
          break;
        case 'Custom Range':
          if (startDate != null && endDate != null) {
            filteredEntries = filteredEntries.where((entry) =>
              entry.date.isAfter(startDate!.subtract(Duration(days: 1))) &&
              entry.date.isBefore(endDate!.add(Duration(days: 1)))
            ).toList();
            return;
          }
          break;
        default:
          break;
      }

      if (selectedTimeRange != 'Custom Range') {
        filteredEntries = filteredEntries.where((entry) => entry.date.isAfter(filterStartDate.subtract(Duration(days: 1)))).toList();
      }
    }

    // Sort by date (newest first)
    filteredEntries.sort((a, b) => b.date.compareTo(a.date));
  }

  /// Build method for the carbon history page, using only ResponsiveHelper and AppTheme/AppColors.
  @override
  Widget build(BuildContext context) {
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
                    _buildFilters(),
                    Expanded(
                      child: _buildEntriesList(),
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

  Widget _buildFilters() {
    final categories = ['All', ...CarbonFootprintDAO.getAllCategories()];
    final timeRanges = ['All Time', 'Today', 'This Week', 'This Month', 'Last 30 Days', 'Last 90 Days', 'Custom Range'];

    return Card(
      margin: ResponsiveHelper.getAdaptivePadding(context),
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Entries',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: categories.map((category) => 
                      DropdownMenuItem(value: category, child: Text(category))
                    ).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                        _applyFilters();
                      });
                    },
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedTimeRange,
                    decoration: InputDecoration(
                      labelText: 'Time Range',
                      border: OutlineInputBorder(),
                    ),
                    items: timeRanges.map((range) => 
                      DropdownMenuItem(value: range, child: Text(range))
                    ).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedTimeRange = value!;
                        if (value == 'Custom Range') {
                          _showDateRangePicker();
                        } else {
                          _applyFilters();
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            if (selectedTimeRange == 'Custom Range') ...[
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showDateRangePicker(),
                      icon: Icon(Icons.calendar_today),
                      label: Text('Select Date Range'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            _buildSummaryStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStats() {
    final totalEntries = filteredEntries.length;
    final totalFootprint = filteredEntries.fold(0.0, (sum, entry) => sum + entry.carbonImpact);
    final averageFootprint = totalEntries > 0 ? totalFootprint / totalEntries : 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Total Entries', '$totalEntries', Icons.list),
        ),
        SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
        Expanded(
          child: _buildStatCard('Total Footprint', '${totalFootprint.toStringAsFixed(1)} kg', Icons.eco),
        ),
        SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
        Expanded(
          child: _buildStatCard('Average', '${averageFootprint.toStringAsFixed(1)} kg', Icons.analytics),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 10),
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesList() {
    if (filteredEntries.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      itemCount: filteredEntries.length,
      itemBuilder: (context, index) {
        final entry = filteredEntries[index];
        return _buildEntryCard(entry);
      },
    );
  }

  Widget _buildEntryCard(CarbonFootprintEntry entry) {
    final activity = CarbonFootprintDAO.getActivityByName(entry.activityType);
    
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: ResponsiveHelper.getAdaptiveSpacing(context) * 1.2,
                  height: ResponsiveHelper.getAdaptiveSpacing(context) * 1.2,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(entry.category),
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.6,
                    ),
                  ),
                  child: Icon(
                    _getCategoryIcon(entry.category),
                    color: AppColors.white,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.activityType,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${entry.value} ${entry.unit}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+${entry.carbonImpact.toStringAsFixed(1)} kg',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy').format(entry.date),
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (entry.notes != null && entry.notes!.isNotEmpty) ...[
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
              Text(
                'Notes: ${entry.notes}',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                  color: AppColors.secondaryText,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (entry.location.isNotEmpty) ...[
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 12,
                    color: AppColors.secondaryText,
                  ),
                  SizedBox(width: 4),
                  Text(
                    entry.location,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(entry.category).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    entry.category,
                    style: TextStyle(
                      fontSize: 10,
                      color: _getCategoryColor(entry.category),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    entry.subcategory,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.info,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Spacer(),
                if (activity != null) ...[
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.secondaryText,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Factor: ${activity.carbonFactor} kg/${activity.unit}',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: AppColors.secondaryText,
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          Text(
            'No entries found',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
              fontWeight: FontWeight.bold,
              color: AppColors.secondaryText,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
          Text(
            'Try adjusting your filters or log your first activity',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              color: AppColors.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
        _applyFilters();
      });
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Transportation': return AppColors.error;
      case 'Energy': return AppColors.warning;
      case 'Food': return AppColors.success;
      case 'Waste': return AppColors.info;
      case 'Water': return AppColors.secondary;
      case 'Digital': return AppColors.mutedText;
      default: return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Transportation': return Icons.directions_car;
      case 'Energy': return Icons.electric_bolt;
      case 'Food': return Icons.restaurant;
      case 'Waste': return Icons.delete;
      case 'Water': return Icons.water_drop;
      case 'Digital': return Icons.computer;
      default: return Icons.eco;
    }
  }
} 