import 'package:flutter/material.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/widgets/header.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';
import 'package:living/services/auth_helper.dart';
import 'package:living/services/notification_service.dart';
import 'package:carousel_slider/carousel_slider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
    
    // Check for notifications after a short delay
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        _notificationService.checkAndShowReminders(context);
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: Header.buildDrawer(context),
      body: SafeArea(
        child: Column(
          children: [
            const Header(),
            Expanded(
              child: SingleChildScrollView(
                padding: ResponsiveHelper.getAdaptivePadding(context),
                child: Column(
                  children: [
                    _buildCarouselSection(context),
                    SizedBox(height: ResponsiveHelper.getSectionSpacing(context)),
                    _buildFeatureGrid(context),
                    SizedBox(height: ResponsiveHelper.getSectionSpacing(context)),
                    _buildCallToActionSection(context),
                  ],
                ),
              ),
            ),
            Footer(),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselSection(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final double height = isMobile ? 220 : 320;
    final List<Map<String, dynamic>> slides = [
      {
        'image': 'assets/logo.png',
        'title': 'Live Sustainably',
        'subtitle': 'Track your carbon footprint and make eco-friendly choices.',
        'icon': Icons.eco,
        'color': AppColors.primary,
        'route': '/carbon-footprint',
      },
      {
        'image': 'assets/icons/', // Placeholder, replace with actual asset if available
        'title': 'Reduce Waste',
        'subtitle': 'Monitor and reduce your daily waste for a cleaner planet.',
        'icon': Icons.recycling,
        'color': AppColors.success,
        'route': '/waste-tracker',
      },
      {
        'image': 'assets/icons/', // Placeholder, replace with actual asset if available
        'title': 'Save Energy',
        'subtitle': 'Discover tips to save energy and lower your carbon impact.',
        'icon': Icons.lightbulb,
        'color': AppColors.warning,
        'route': '/energy-tips',
      },
      {
        'image': 'assets/icons/', // Placeholder, replace with actual asset if available
        'title': 'Shop Green',
        'subtitle': 'Find eco-friendly products and support sustainable brands.',
        'icon': Icons.shopping_bag,
        'color': AppColors.info,
        'route': '/search',
      },
      {
        'image': 'assets/icons/', // Placeholder, replace with actual asset if available
        'title': 'Join Challenges',
        'subtitle': 'Participate in sustainability challenges and earn rewards.',
        'icon': Icons.emoji_events,
        'color': AppColors.secondary,
        'route': '/challenges',
      },
    ];

    return CarouselSlider(
      options: CarouselOptions(
        height: height,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: isMobile ? 0.92 : 0.6,
        aspectRatio: isMobile ? 1.2 : 2.5,
        autoPlayInterval: Duration(seconds: 5),
      ),
      items: slides.map((slide) {
        return Builder(
          builder: (BuildContext context) {
            return InkWell(
              borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
              onTap: () {
                if (slide['route'] != null) {
                  Navigator.pushNamed(context, slide['route']);
                }
              },
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [slide['color'].withOpacity(0.12), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
                  boxShadow: [
                    BoxShadow(
                      color: slide['color'].withOpacity(0.08),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(width: 16),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: slide['color'].withOpacity(0.13),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        slide['icon'],
                        size: isMobile ? 48 : 64,
                        color: slide['color'],
                      ),
                    ),
                    SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slide['title'],
                            style: TextStyle(
                              fontSize: isMobile ? 20 : 28,
                              fontWeight: FontWeight.bold,
                              color: slide['color'],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            slide['subtitle'],
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 18,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                  ],
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildMobileHeroContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: EdgeInsets.all(ResponsiveHelper.getAdaptiveSpacing(context)),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.eco,
              size: ResponsiveHelper.getAdaptiveIconSize(context) * 2,
              color: AppColors.primary,
            ),
          ),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
        Text(
          'Welcome to',
          style: TextStyle(
            fontSize: ResponsiveHelper.getBodyFontSize(context),
            color: AppColors.secondaryText,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
        Text(
          'Sustainable Living',
          style: TextStyle(
            fontSize: ResponsiveHelper.getTitleFontSize(context) * 1.3,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
        Text(
          'Your comprehensive platform for eco-friendly living, sustainable products, and environmental awareness. Start your journey towards a greener future today.',
          style: TextStyle(
            fontSize: ResponsiveHelper.getBodyFontSize(context),
            color: AppColors.secondaryText,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 1.5),
        _buildMobileHeroButtons(context),
      ],
    );
  }

  Widget _buildDesktopHeroContent(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getBodyFontSize(context),
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
              Text(
                'Sustainable Living',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getTitleFontSize(context) * 1.4,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Text(
                'Your comprehensive platform for eco-friendly living, sustainable products, and environmental awareness. Start your journey towards a greener future today.',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getBodyFontSize(context),
                  color: AppColors.secondaryText,
                  height: 1.6,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 1.5),
              _buildDesktopHeroButtons(context),
            ],
          ),
        ),
        SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 2),
        Expanded(
          flex: 1,
          child: Container(
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                ),
                Icon(
                  Icons.eco,
                  size: 120,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHeroButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/auth'),
            icon: Icon(Icons.login, size: ResponsiveHelper.getCompactIconSize(context)),
            label: Text(
              'Get Started',
              style: TextStyle(
                fontSize: ResponsiveHelper.getButtonFontSize(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getAdaptiveSpacing(context),
                vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.75,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getAdaptiveBorderRadius(context),
                ),
              ),
              elevation: 4,
            ),
          ),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/about-us'),
            icon: Icon(Icons.info_outline, size: ResponsiveHelper.getCompactIconSize(context)),
            label: Text(
              'Learn More',
              style: TextStyle(
                fontSize: ResponsiveHelper.getButtonFontSize(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary, width: 2),
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getAdaptiveSpacing(context),
                vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.75,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getAdaptiveBorderRadius(context),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopHeroButtons(BuildContext context) {
    return Wrap(
      spacing: ResponsiveHelper.getAdaptiveGap(context),
      runSpacing: ResponsiveHelper.getAdaptiveGap(context),
      children: [
        ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/auth'),
          icon: Icon(Icons.login, size: ResponsiveHelper.getCompactIconSize(context)),
          label: Text(
            'Get Started',
            style: TextStyle(
              fontSize: ResponsiveHelper.getButtonFontSize(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 1.5,
              vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.75,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getAdaptiveBorderRadius(context),
              ),
            ),
            elevation: 4,
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/about-us'),
          icon: Icon(Icons.info_outline, size: ResponsiveHelper.getCompactIconSize(context)),
          label: Text(
            'Learn More',
            style: TextStyle(
              fontSize: ResponsiveHelper.getButtonFontSize(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary, width: 2),
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 1.5,
              vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.75,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getAdaptiveBorderRadius(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    final stats = [
      {'label': 'Carbon Footprint', 'value': 'Track', 'icon': Icons.cloud, 'color': AppColors.primary},
      {'label': 'Waste Reduction', 'value': 'Monitor', 'icon': Icons.recycling, 'color': AppColors.success},
      {'label': 'Energy Tips', 'value': 'Learn', 'icon': Icons.lightbulb, 'color': AppColors.warning},
      {'label': 'Eco Products', 'value': 'Shop', 'icon': Icons.shopping_bag, 'color': AppColors.info},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What We Offer',
          style: TextStyle(
            fontSize: ResponsiveHelper.getSubtitleFontSize(context),
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
        if (ResponsiveHelper.isMobile(context))
          Column(
            children: stats.map((stat) => _buildMobileStatCard(context, stat)).toList(),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: ResponsiveHelper.getAdaptiveSpacing(context),
              mainAxisSpacing: ResponsiveHelper.getAdaptiveSpacing(context),
            ),
            itemCount: stats.length,
            itemBuilder: (context, index) => _buildDesktopStatCard(context, stats[index]),
          ),
      ],
    );
  }

  Widget _buildMobileStatCard(BuildContext context, Map<String, dynamic> stat) {
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
      elevation: ResponsiveHelper.getAdaptiveElevation(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
        onTap: () {},
        child: Padding(
          padding: ResponsiveHelper.getCardPadding(context),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveHelper.getAdaptiveGap(context)),
                decoration: BoxDecoration(
                  color: (stat['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  stat['icon'] as IconData,
                  color: stat['color'] as Color,
                  size: ResponsiveHelper.getAdaptiveIconSize(context),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getAdaptiveGap(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat['value'] as String,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getSubtitleFontSize(context),
                        fontWeight: FontWeight.bold,
                        color: stat['color'] as Color,
                      ),
                    ),
                    Text(
                      stat['label'] as String,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getBodyFontSize(context),
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopStatCard(BuildContext context, Map<String, dynamic> stat) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: ResponsiveHelper.getAdaptiveElevation(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
        onTap: () {},
        child: Padding(
          padding: ResponsiveHelper.getCardPadding(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveHelper.getAdaptiveGap(context)),
                decoration: BoxDecoration(
                  color: (stat['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  stat['icon'] as IconData,
                  color: stat['color'] as Color,
                  size: ResponsiveHelper.getAdaptiveIconSize(context) * 1.2,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Text(
                stat['value'] as String,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getSubtitleFontSize(context),
                  fontWeight: FontWeight.bold,
                  color: stat['color'] as Color,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.25),
              Text(
                stat['label'] as String,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getBodyFontSize(context),
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    final currentUserId = AuthService.getCurrentUserId();
    final features = [
      {
        'title': 'Carbon Footprint Tracker',
        'subtitle': 'Track your daily carbon emissions and reduce your environmental impact.',
        'icon': Icons.cloud,
        'route': '/carbon-footprint',
        'requiresAuth': true,
        'color': AppColors.primary,
        'gradient': [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
      },
      {
        'title': 'Sustainable Challenges',
        'subtitle': 'Participate in eco-friendly challenges and earn rewards.',
        'icon': Icons.emoji_events,
        'route': '/challenges',
        'requiresAuth': true,
        'color': AppColors.success,
        'gradient': [AppColors.success, AppColors.success.withValues(alpha: 0.7)],
      },
      {
        'title': 'Waste Reduction Tracker',
        'subtitle': 'Monitor your waste reduction efforts and set goals.',
        'icon': Icons.recycling,
        'route': '/waste-tracker',
        'requiresAuth': true,
        'color': AppColors.info,
        'gradient': [AppColors.info, AppColors.info.withValues(alpha: 0.7)],
      },
      {
        'title': 'Progress Dashboard',
        'subtitle': 'View your sustainability progress and achievements.',
        'icon': Icons.analytics,
        'route': '/progress-dashboard',
        'requiresAuth': true,
        'color': AppColors.warning,
        'gradient': [AppColors.warning, AppColors.warning.withValues(alpha: 0.7)],
      },
      {
        'title': 'Green Certifications',
        'subtitle': 'Learn about eco-labels and sustainable product certifications.',
        'icon': Icons.verified,
        'route': '/certifications',
        'requiresAuth': false,
        'color': AppColors.success,
        'gradient': [AppColors.success, AppColors.success.withValues(alpha: 0.7)],
      },
      {
        'title': 'Energy Conservation Tips',
        'subtitle': 'Discover ways to save energy and reduce your carbon footprint.',
        'icon': Icons.lightbulb,
        'route': '/energy-tips',
        'requiresAuth': false,
        'color': AppColors.warning,
        'gradient': [AppColors.warning, AppColors.warning.withValues(alpha: 0.7)],
      },
      {
        'title': 'Eco-Travel Guide',
        'subtitle': 'Find sustainable travel options and eco-friendly destinations.',
        'icon': Icons.travel_explore,
        'route': '/eco-travel',
        'requiresAuth': false,
        'color': AppColors.info,
        'gradient': [AppColors.info, AppColors.info.withValues(alpha: 0.7)],
      },
      {
        'title': 'Educational Content',
        'subtitle': 'Read articles and watch videos about sustainability.',
        'icon': Icons.school,
        'route': '/educational-content',
        'requiresAuth': false,
        'color': AppColors.primary,
        'gradient': [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
      },
      {
        'title': 'Sustainable Recipes',
        'subtitle': 'Cook delicious meals with eco-friendly ingredients.',
        'icon': Icons.restaurant,
        'route': '/recipes',
        'requiresAuth': false,
        'color': AppColors.success,
        'gradient': [AppColors.success, AppColors.success.withValues(alpha: 0.7)],
      },
      {
        'title': 'Community Forum',
        'subtitle': 'Connect with others and share your sustainability journey.',
        'icon': Icons.forum,
        'route': '/forum',
        'requiresAuth': true,
        'color': AppColors.info,
        'gradient': [AppColors.info, AppColors.info.withValues(alpha: 0.7)],
      },
      {
        'title': 'Image Gallery',
        'subtitle': 'Browse inspiring images of sustainable living.',
        'icon': Icons.photo_library,
        'route': '/gallery',
        'requiresAuth': false,
        'color': AppColors.warning,
        'gradient': [AppColors.warning, AppColors.warning.withValues(alpha: 0.7)],
      },
      {
        'title': 'Eco-Friendly Products',
        'subtitle': 'Shop for sustainable products and green alternatives.',
        'icon': Icons.shopping_bag,
        'route': '/search',
        'requiresAuth': false,
        'color': AppColors.primary,
        'gradient': [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explore Features',
          style: TextStyle(
            fontSize: ResponsiveHelper.getSubtitleFontSize(context),
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
        _buildImageGridFeature(context, features, currentUserId),
      ],
    );
  }

  Widget _buildImageGridFeature(BuildContext context, List<Map<String, dynamic>> features, String? currentUserId) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final crossAxisCount = isMobile ? 2 : 3;
    final double childAspectRatio = isMobile ? 1.0 : 1.1;
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
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _handleFeatureNavigation(context, feature),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight.withOpacity(0.08),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 1.5,
              horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: (feature['color'] as Color).withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      feature['icon'] as IconData,
                      color: feature['color'] as Color,
                      size: ResponsiveHelper.getAdaptiveIconSize(context) * 1.3,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                  Text(
                    feature['title'] as String,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getSubtitleFontSize(context),
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                  Text(
                    feature['subtitle'] as String,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getBodyFontSize(context) * 0.95,
                      color: AppColors.secondaryText,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((feature['requiresAuth'] as bool) && currentUserId == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Icon(
                        Icons.lock,
                        color: AppColors.mutedText,
                        size: ResponsiveHelper.getCompactIconSize(context),
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

  Widget _buildMobileFeatureGrid(BuildContext context, List<Map<String, dynamic>> features, String? currentUserId) {
    return Column(
      children: features.map((feature) {
        return Card(
          margin: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
          elevation: ResponsiveHelper.getAdaptiveElevation(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
            onTap: () => _handleFeatureNavigation(context, feature),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    (feature['color'] as Color).withValues(alpha: 0.02),
                  ],
                ),
              ),
              padding: ResponsiveHelper.getCardPadding(context),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(ResponsiveHelper.getAdaptiveGap(context)),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: feature['gradient'] as List<Color>,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (feature['color'] as Color).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      feature['icon'] as IconData,
                      color: Colors.white,
                      size: ResponsiveHelper.getAdaptiveIconSize(context),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveGap(context)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                feature['title'] as String,
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.getSubtitleFontSize(context),
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryText,
                                ),
                              ),
                            ),
                            if ((feature['requiresAuth'] as bool) && currentUserId == null)
                              Icon(
                                Icons.lock,
                                color: AppColors.mutedText,
                                size: ResponsiveHelper.getCompactIconSize(context),
                              ),
                          ],
                        ),
                        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.25),
                        Text(
                          feature['subtitle'] as String,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getBodyFontSize(context),
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDesktopFeatureGrid(BuildContext context, List<Map<String, dynamic>> features, String? currentUserId) {
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
            borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
            onTap: () => _handleFeatureNavigation(context, feature),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    (feature['color'] as Color).withValues(alpha: 0.02),
                  ],
                ),
              ),
              padding: ResponsiveHelper.getCardPadding(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(ResponsiveHelper.getAdaptiveGap(context)),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: feature['gradient'] as List<Color>,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (feature['color'] as Color).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      feature['icon'] as IconData,
                      color: Colors.white,
                      size: ResponsiveHelper.getAdaptiveIconSize(context) * 1.5,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          feature['title'] as String,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getSubtitleFontSize(context),
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if ((feature['requiresAuth'] as bool) && currentUserId == null)
                        Icon(
                          Icons.lock,
                          color: AppColors.mutedText,
                          size: ResponsiveHelper.getCompactIconSize(context),
                        ),
                    ],
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleFeatureNavigation(BuildContext context, Map<String, dynamic> feature) {
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
  }

  Widget _buildCallToActionSection(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
            AppColors.secondary,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: ResponsiveHelper.getCardPadding(context),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(ResponsiveHelper.getAdaptiveSpacing(context)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.eco,
              size: ResponsiveHelper.getAdaptiveIconSize(context) * 2,
              color: Colors.white,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          Text(
            'Ready to Start Your Sustainable Journey?',
            style: TextStyle(
              fontSize: ResponsiveHelper.getSubtitleFontSize(context),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
          Text(
            'Join thousands of users who are already making a difference for our planet.',
            style: TextStyle(
              fontSize: ResponsiveHelper.getBodyFontSize(context),
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/auth'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 2,
                vertical: ResponsiveHelper.getAdaptiveSpacing(context),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
              ),
              elevation: 4,
            ),
            child: Text(
              'Join Now',
              style: TextStyle(
                fontSize: ResponsiveHelper.getButtonFontSize(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


