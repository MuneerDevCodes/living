import 'package:flutter/material.dart';
import 'package:living/models/carbon_footprint_model.dart';
import 'package:living/services/carbon_footprint_dao.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';

class CarbonDashboardWidget extends StatefulWidget {
  final String userId;
  final VoidCallback? onRefresh;

  const CarbonDashboardWidget({
    super.key,
    required this.userId,
    this.onRefresh,
  });

  @override
  State<CarbonDashboardWidget> createState() => _CarbonDashboardWidgetState();
}

class _CarbonDashboardWidgetState extends State<CarbonDashboardWidget> {
  CarbonAnalytics? analytics;
  List<CarbonFootprintEntry> entries = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);
      entries = await CarbonFootprintDAO.getUserEntries(widget.userId);
      analytics = await CarbonFootprintDAO.getUserAnalytics(widget.userId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load dashboard data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (analytics == null) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      child: Column(
        children: [
          _buildSummaryCards(),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          _buildChartSection(),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          _buildTrendsSection(),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          _buildRecommendationsSection(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Daily Average',
            value: '${analytics!.weeklyAverage.toStringAsFixed(1)}',
            unit: 'kg CO2',
            color: AppColors.primary,
            icon: Icons.eco,
          ),
        ),
        SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
        Expanded(
          child: _buildSummaryCard(
            title: 'Total Entries',
            value: '${analytics!.totalEntries}',
            unit: 'activities',
            color: AppColors.info,
            icon: Icons.list,
          ),
        ),
        SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
        Expanded(
          child: _buildSummaryCard(
            title: 'Reduction',
            value: '${analytics!.reductionPercentage.toStringAsFixed(1)}',
            unit: '%',
            color: AppColors.success,
            icon: Icons.trending_down,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String unit,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            Text(
              value,
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 20),
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                color: AppColors.secondaryText,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
            Text(
              title,
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: AppColors.primary, size: 24),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                Text(
                  'Category Breakdown',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            _buildCategoryChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart() {
    if (analytics?.categoryBreakdown == null) return SizedBox.shrink();

    final categories = analytics!.categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: categories.take(5).map((category) {
        final percentage = (category.value / analytics!.totalFootprint * 100);
        return Padding(
          padding: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8,
                    height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(category.key),
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.4,
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                  Expanded(
                    child: Text(
                      category.key,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      fontWeight: FontWeight.bold,
                      color: _getCategoryColor(category.key),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
              LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: AppColors.borderLight,
                valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor(category.key)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrendsSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: AppColors.primary, size: 24),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                Text(
                  'Weekly Trends',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            _buildTrendChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart() {
    if (analytics?.weeklyTrend == null) return SizedBox.shrink();

    final trendData = analytics!.weeklyTrend.entries.toList();
    final maxValue = trendData.fold(0.0, (max, entry) => entry.value > max ? entry.value : max);

    return Column(
      children: trendData.map((entry) {
        final percentage = maxValue > 0 ? (entry.value / maxValue) : 0.0;
        return Padding(
          padding: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
          child: Row(
            children: [
              SizedBox(
                width: ResponsiveHelper.getAdaptiveSpacing(context) * 3,
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: AppColors.borderLight,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
              Text(
                '${entry.value.toStringAsFixed(1)} kg',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecommendationsSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: AppColors.warning, size: 24),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                Text(
                  'Personalized Recommendations',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            _buildRecommendationsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsList() {
    final tips = CarbonFootprintDAO.getGeneralTips().take(3).toList();
    
    return Column(
      children: tips.map((tip) => Padding(
        padding: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: ResponsiveHelper.getAdaptiveIconSize(context),
            ),
            SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
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
      )).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics,
            size: 64,
            color: AppColors.secondaryText,
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          Text(
            'No data available',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
              fontWeight: FontWeight.bold,
              color: AppColors.secondaryText,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
          Text(
            'Start logging activities to see your dashboard',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
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
}

class CarbonChartWidget extends StatelessWidget {
  final Map<String, double> data;
  final String title;
  final Color? primaryColor;

  const CarbonChartWidget({
    super.key,
    required this.data,
    required this.title,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            _buildChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    final entries = data.entries.toList();
    final maxValue = entries.fold(0.0, (max, entry) => entry.value > max ? entry.value : max);

    return Column(
      children: entries.map((entry) {
        final percentage = maxValue > 0 ? (entry.value / maxValue) : 0.0;
        return Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  entry.key,
                  style: TextStyle(fontSize: 12),
                ),
              ),
              Expanded(
                flex: 3,
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: AppColors.borderLight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    primaryColor ?? AppColors.primary,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                '${entry.value.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class CarbonProgressWidget extends StatelessWidget {
  final double currentValue;
  final double targetValue;
  final String label;
  final Color? color;

  const CarbonProgressWidget({
    super.key,
    required this.currentValue,
    required this.targetValue,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentValue / targetValue).clamp(0.0, 1.0);
    final progressColor = color ?? (currentValue <= targetValue ? AppColors.success : AppColors.warning);

    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
            Text(
              '${currentValue.toStringAsFixed(1)} / ${targetValue.toStringAsFixed(1)} kg CO2',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                color: AppColors.secondaryText,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
            Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                fontWeight: FontWeight.bold,
                color: progressColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CarbonComparisonWidget extends StatelessWidget {
  final double userValue;
  final double averageValue;
  final double targetValue;
  final String label;

  const CarbonComparisonWidget({
    super.key,
    required this.userValue,
    required this.averageValue,
    required this.targetValue,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            _buildComparisonRow('Your Average', userValue, AppColors.primary),
            _buildComparisonRow('Global Average', averageValue, AppColors.warning),
            _buildComparisonRow('Target', targetValue, AppColors.success),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(String label, double value, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14),
            ),
          ),
          Text(
            '${value.toStringAsFixed(1)} kg/day',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
} 