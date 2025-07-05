import 'package:flutter/material.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/widgets/header.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Header.buildDrawer(context),
      body: Column(
        children: [
          const Header(),
          Expanded(
            child: Stack(
              children: [
                ListView(
                  padding: ResponsiveHelper.getAdaptivePadding(context),
                  children: [
                    _buildWelcomeSection(context),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                    _buildFeatureList(context),
                  ],
                ),
              ],
            ),
          ),
          const Footer(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getAdaptiveBorderRadius(context),
        ),
      ),
      child: Padding(
        padding: ResponsiveHelper.getCardPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to Living',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 24),
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
            Text(
              'Discover sustainable products and eco-friendly living solutions.',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureList(BuildContext context) {
    final features = [
      {
        'title': 'Introduction to Sustainable Living',
        'subtitle': 'Learn the basics of sustainable living.',
        'icon': Icons.eco,
      },
      {
        'title': 'Eco-Friendly Practices',
        'subtitle': 'Discover eco-friendly practices for daily life.',
        'icon': Icons.recycling,
      },
      {
        'title': 'Sustainable Products',
        'subtitle': 'Find sustainable products for your home.',
        'icon': Icons.home,
      },
      {
        'title': 'Community Initiatives',
        'subtitle': 'Get involved in local sustainability initiatives.',
        'icon': Icons.people,
      },
    ];

    return Column(
      children: features.map((feature) {
        return Card(
          margin: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.8,
            ),
          ),
          child: ListTile(
            leading: Icon(
              feature['icon'] as IconData,
              color: Theme.of(context).colorScheme.primary,
              size: ResponsiveHelper.getAdaptiveIconSize(context),
            ),
            title: Text(
              feature['title'] as String,
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              feature['subtitle'] as String,
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                color: AppColors.secondaryText,
              ),
            ),
            onTap: () {
              // Navigate to search page with the feature as query
              Navigator.pushNamed(
                context,
                '/search',
                arguments: feature['title'],
              );
            },
          ),
        );
      }).toList(),
    );
  }
}
