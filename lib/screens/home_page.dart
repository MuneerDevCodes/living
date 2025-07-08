import 'package:flutter/material.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/widgets/header.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';
import 'package:living/services/auth_helper.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                    SizedBox(height: ResponsiveHelper.getSectionSpacing(context)),
                    _buildFeatureGrid(context),
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

  Widget _buildWelcomeSection(BuildContext context) {
    return Card(
      elevation: ResponsiveHelper.getAdaptiveElevation(context),
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
              'Welcome to Sustainable Living Guide',
              style: TextStyle(
                fontSize: ResponsiveHelper.getTitleFontSize(context),
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
            Text(
              'Your comprehensive platform for sustainable living, eco-friendly products, and environmental awareness.',
              style: TextStyle(
                fontSize: ResponsiveHelper.getBodyFontSize(context),
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    final features = [
      {
        'title': 'Carbon Footprint Tracker',
        'subtitle': 'Track your daily carbon emissions and reduce your environmental impact.',
        'icon': Icons.cloud,
        'route': '/carbon-footprint',
        'requiresAuth': true,
      },
      {
        'title': 'Sustainable Challenges',
        'subtitle': 'Participate in eco-friendly challenges and earn rewards.',
        'icon': Icons.emoji_events,
        'route': '/challenges',
        'requiresAuth': true,
      },
      {
        'title': 'Waste Reduction Tracker',
        'subtitle': 'Monitor your waste reduction efforts and set goals.',
        'icon': Icons.recycling,
        'route': '/waste-tracker',
        'requiresAuth': true,
      },
      {
        'title': 'Progress Dashboard',
        'subtitle': 'View your sustainability progress and achievements.',
        'icon': Icons.analytics,
        'route': '/progress-dashboard',
        'requiresAuth': true,
      },
      {
        'title': 'Green Certifications',
        'subtitle': 'Learn about eco-labels and sustainable product certifications.',
        'icon': Icons.verified,
        'route': '/certifications',
        'requiresAuth': false,
      },
      {
        'title': 'Energy Conservation Tips',
        'subtitle': 'Discover ways to save energy and reduce your carbon footprint.',
        'icon': Icons.lightbulb,
        'route': '/energy-tips',
        'requiresAuth': false,
      },
      {
        'title': 'Eco-Travel Guide',
        'subtitle': 'Find sustainable travel options and eco-friendly destinations.',
        'icon': Icons.travel_explore,
        'route': '/eco-travel',
        'requiresAuth': false,
      },
      {
        'title': 'Educational Content',
        'subtitle': 'Read articles and watch videos about sustainability.',
        'icon': Icons.school,
        'route': '/educational-content',
        'requiresAuth': false,
      },
      {
        'title': 'Sustainable Recipes',
        'subtitle': 'Cook delicious meals with eco-friendly ingredients.',
        'icon': Icons.restaurant,
        'route': '/recipes',
        'requiresAuth': false,
      },
      {
        'title': 'Community Forum',
        'subtitle': 'Connect with others and share your sustainability journey.',
        'icon': Icons.forum,
        'route': '/forum',
        'requiresAuth': true,
      },
      {
        'title': 'Image Gallery',
        'subtitle': 'Browse inspiring images of sustainable living.',
        'icon': Icons.photo_library,
        'route': '/gallery',
        'requiresAuth': false,
      },
      {
        'title': 'Eco-Friendly Products',
        'subtitle': 'Shop for sustainable products and green alternatives.',
        'icon': Icons.shopping_bag,
        'route': '/search',
        'requiresAuth': false,
      },
    ];

    if (ResponsiveHelper.isMobile(context)) {
      return _buildMobileFeatureList(context, features);
    } else {
      return _buildDesktopFeatureGrid(context, features);
    }
  }

  Widget _buildMobileFeatureList(BuildContext context, List<Map<String, dynamic>> features) {
    return Column(
      children: features.map((feature) {
        return Card(
          margin: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
          elevation: ResponsiveHelper.getAdaptiveElevation(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.8,
            ),
          ),
          child: ListTile(
            contentPadding: ResponsiveHelper.getCardPadding(context),
            leading: Icon(
              feature['icon'] as IconData,
              color: Theme.of(context).colorScheme.primary,
              size: ResponsiveHelper.getAdaptiveIconSize(context),
            ),
            title: Text(
              feature['title'] as String,
              style: TextStyle(
                fontSize: ResponsiveHelper.getSubtitleFontSize(context),
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              feature['subtitle'] as String,
              style: TextStyle(
                fontSize: ResponsiveHelper.getBodyFontSize(context),
                color: AppColors.secondaryText,
              ),
            ),
            trailing: feature['requiresAuth'] as bool
                ? Icon(Icons.lock, color: AppColors.mutedText, size: ResponsiveHelper.getAdaptiveIconSize(context))
                : null,
            onTap: () {
              if (feature['requiresAuth'] as bool) {
                // Check if user is authenticated using auth helper
                final currentUserId = AuthService.getCurrentUserId();
                if (currentUserId == null) {
                  // User is not authenticated, navigate to auth page
                  Navigator.pushNamed(context, '/auth');
                } else {
                  // User is authenticated, navigate to the feature
                  Navigator.pushNamed(context, feature['route'] as String);
                }
              } else {
                // Feature doesn't require auth, navigate directly
                Navigator.pushNamed(context, feature['route'] as String);
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDesktopFeatureGrid(BuildContext context, List<Map<String, dynamic>> features) {
    final crossAxisCount = ResponsiveHelper.getAdaptiveCrossAxisCount(context);
    final childAspectRatio = ResponsiveHelper.getGridChildAspectRatio(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: ResponsiveHelper.getAdaptiveSpacing(context),
        mainAxisSpacing: ResponsiveHelper.getAdaptiveSpacing(context),
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return Card(
          elevation: ResponsiveHelper.getAdaptiveElevation(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getAdaptiveBorderRadius(context),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getAdaptiveBorderRadius(context),
            ),
            onTap: () {
              if (feature['requiresAuth'] as bool) {
                final currentUserId = AuthService.getCurrentUserId();
                if (currentUserId == null) {
                  Navigator.pushNamed(context, '/auth');
                } else {
                  Navigator.pushNamed(context, feature['route'] as String);
                }
              } else {
                Navigator.pushNamed(context, feature['route'] as String);
              }
            },
            child: Padding(
              padding: ResponsiveHelper.getCardPadding(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    feature['icon'] as IconData,
                    color: Theme.of(context).colorScheme.primary,
                    size: ResponsiveHelper.getAdaptiveIconSize(context) * 1.5,
                  ),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                  Text(
                    feature['title'] as String,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getSubtitleFontSize(context),
                      fontWeight: FontWeight.bold,
                      textAlign: TextAlign.center,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                  Text(
                    feature['subtitle'] as String,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getBodyFontSize(context),
                      color: AppColors.secondaryText,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (feature['requiresAuth'] as bool)
                    Padding(
                      padding: EdgeInsets.only(top: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                      child: Icon(
                        Icons.lock,
                        color: AppColors.mutedText,
                        size: ResponsiveHelper.getAdaptiveIconSize(context) * 0.8,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
