import 'package:flutter/material.dart';
import 'package:living/style/theme.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:fl_chart/fl_chart.dart';

/// StyleGuidePage demonstrates all core styling elements used in the app.
class StyleGuidePage extends StatelessWidget {
  const StyleGuidePage({super.key});
  static const String routeName = '/style-guide';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('App Colors'),
                    _buildColorRow(),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                    _buildSectionTitle('Typography'),
                    _buildTypographyDemo(context),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                    _buildSectionTitle('Spacing & Padding'),
                    _buildSpacingDemo(context),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                    _buildSectionTitle('Buttons'),
                    _buildButtonDemo(context),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                    _buildSectionTitle('Tabs'),
                    _buildTabsDemo(context),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                    _buildSectionTitle('Cards'),
                    _buildCardDemo(context),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                    _buildSectionTitle('Forms'),
                    _buildFormDemo(context),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                    _buildSectionTitle('Lists'),
                    _buildListDemo(context),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                    _buildSectionTitle('Dialogs'),
                    _buildDialogDemo(context),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                    _buildSectionTitle('Charts'),
                    _buildChartDemo(context),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                    _buildSectionTitle('Filters'),
                    _buildFilterDemo(context),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                    _buildSectionTitle('Reusable Widgets'),
                    _buildWidgetDemo(context),
                  ],
                ),
              ),
            ),
          ),
          Footer(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
  );

  Widget _buildColorRow() {
    final colorList = [
      {'name': 'Primary', 'color': AppColors.primary},
      {'name': 'Secondary', 'color': AppColors.secondary},
      {'name': 'Background', 'color': AppColors.background},
      {'name': 'Success', 'color': AppColors.success},
      {'name': 'Warning', 'color': AppColors.warning},
      {'name': 'Error', 'color': AppColors.error},
      {'name': 'Info', 'color': AppColors.info},
      {'name': 'Text', 'color': AppColors.primaryText},
      {'name': 'Muted', 'color': AppColors.mutedText},
    ];
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: colorList.map((c) => Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c['color'] as Color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
            ),
          ),
          SizedBox(height: 4),
          Text(c['name'] as String, style: TextStyle(fontSize: 12)),
        ],
      )).toList(),
    );
  }

  Widget _buildTypographyDemo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Heading 1', style: TextStyle(fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 24), fontWeight: FontWeight.bold)),
        Text('Heading 2', style: TextStyle(fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 20), fontWeight: FontWeight.w600)),
        Text('Subtitle', style: TextStyle(fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16), fontWeight: FontWeight.w500, color: AppColors.secondaryText)),
        Text('Body text goes here. This is the default body style.', style: TextStyle(fontSize: ResponsiveHelper.getBodyFontSize(context), color: AppColors.primaryText)),
        Text('Caption text', style: TextStyle(fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12), color: AppColors.mutedText)),
      ],
    );
  }

  Widget _buildSpacingDemo(BuildContext context) {
    return Row(
      children: [
        Container(width: 40, height: ResponsiveHelper.getAdaptiveSpacing(context), color: AppColors.primary),
        SizedBox(width: 8),
        Text('Adaptive Spacing'),
        SizedBox(width: 16),
        Container(width: 40, height: ResponsiveHelper.getAdaptiveGap(context), color: AppColors.secondary),
        SizedBox(width: 8),
        Text('Adaptive Gap'),
        SizedBox(width: 16),
        Container(width: 40, height: ResponsiveHelper.getAdaptiveBorderRadius(context), color: AppColors.warning),
        SizedBox(width: 8),
        Text('Border Radius'),
      ],
    );
  }

  Widget _buildCardDemo(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
      ),
      child: Padding(
        padding: ResponsiveHelper.getCardPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Card Title', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('This is a sample card using the app style.'),
            SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                  child: Text('Primary'),
                ),
                SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                  child: Text('Outlined'),
                ),
                SizedBox(width: 8),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.linkColor,
                  ),
                  child: Text('Link'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWidgetDemo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Header & Footer:', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Icon(Icons.menu, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Header/Drawer Example'),
              ],
            ),
          ),
        ),
        SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Icon(Icons.info, color: AppColors.info),
                SizedBox(width: 8),
                Text('Footer Example'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Buttons Demo
  Widget _buildButtonDemo(BuildContext context) {
    return Row(
      children: [
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
          ),
          child: Text('Primary'),
        ),
        SizedBox(width: 8),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
          ),
          child: Text('Outlined'),
        ),
        SizedBox(width: 8),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: AppColors.linkColor,
          ),
          child: Text('Link'),
        ),
      ],
    );
  }

  /// Tabs Demo
  Widget _buildTabsDemo(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: AppColors.primary,
            child: TabBar(
              indicatorColor: AppColors.white,
              labelColor: AppColors.white,
              unselectedLabelColor: AppColors.white.withOpacity(0.7),
              tabs: const [
                Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
                Tab(icon: Icon(Icons.add), text: 'Log'),
                Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
              ],
            ),
          ),
          Container(
            height: 120,
            child: TabBarView(
              children: [
                Center(child: Text('Overview Tab Content')),
                Center(child: Text('Log Tab Content')),
                Center(child: Text('Analytics Tab Content')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Forms Demo
  Widget _buildFormDemo(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _controller = TextEditingController();
    String? dropdownValue = 'Option 1';
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Text Field',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
          ),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: dropdownValue,
            decoration: InputDecoration(
              labelText: 'Dropdown',
              border: OutlineInputBorder(),
            ),
            items: ['Option 1', 'Option 2', 'Option 3']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (value) {},
          ),
          SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Form is valid!')),
                );
              }
            },
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }

  /// Lists Demo
  Widget _buildListDemo(BuildContext context) {
    final items = List.generate(5, (i) => 'List Item ${i + 1}');
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => Divider(height: 1),
        itemBuilder: (context, index) => ListTile(
          leading: CircleAvatar(child: Text('${index + 1}')),
          title: Text(items[index]),
          subtitle: Text('Subtitle for ${items[index]}'),
          trailing: Icon(Icons.chevron_right),
        ),
      ),
    );
  }

  /// Dialogs Demo
  Widget _buildDialogDemo(BuildContext context) {
    return Row(
      children: [
        ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Dialog Title'),
                content: Text('This is a sample dialog.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close'),
                  ),
                ],
              ),
            );
          },
          child: Text('Show Dialog'),
        ),
        SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success),
                    SizedBox(width: 8),
                    Text('Success!'),
                  ],
                ),
                content: Text('This is a success dialog.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('OK'),
                  ),
                ],
              ),
            );
          },
          child: Text('Show Success'),
        ),
      ],
    );
  }

  /// Charts Demo (PieChart/BarChart)
  Widget _buildChartDemo(BuildContext context) {
    // Minimal PieChart using fl_chart (if available)
    return Card(
      child: SizedBox(
        height: 180,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(value: 40, color: AppColors.primary, title: 'A'),
                PieChartSectionData(value: 30, color: AppColors.success, title: 'B'),
                PieChartSectionData(value: 20, color: AppColors.warning, title: 'C'),
                PieChartSectionData(value: 10, color: AppColors.error, title: 'D'),
              ],
              sectionsSpace: 2,
              centerSpaceRadius: 32,
            ),
          ),
        ),
      ),
    );
  }

  /// Filters Demo
  Widget _buildFilterDemo(BuildContext context) {
    String? selectedCategory = 'All';
    String? selectedTime = 'All Time';
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: selectedCategory,
            decoration: InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: ['All', 'Transportation', 'Energy', 'Food']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (value) {},
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: selectedTime,
            decoration: InputDecoration(
              labelText: 'Time Range',
              border: OutlineInputBorder(),
            ),
            items: ['All Time', 'Today', 'This Week', 'This Month']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (value) {},
          ),
        ),
      ],
    );
  }
} 