import 'package:flutter/material.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/widgets/header.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';
import 'package:living/services/auth_helper.dart';
import 'package:living/services/performance_service.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:living/services/admin_service.dart';

/// HomePage is the main landing page, fully responsive and theme-driven.
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
  int _currentCarouselIndex = 0;
  //final NotificationService _notificationService = NotificationService();
  String? _userRole;
  bool _loadingRole = true;

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
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final role = await AdminService().getCurrentUserRole();
    if (mounted) {
      setState(() {
        _userRole = role;
        _loadingRole = false;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  /// Build method for the home page, using only ResponsiveHelper and AppTheme/AppColors.
  @override
  Widget build(BuildContext context) {
    if (_loadingRole) {
      return const Center(child: CircularProgressIndicator());
    }
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
    final double height = isMobile ? 200 : 280;
    
    final List<Map<String, dynamic>> slides = [
      {
        'title': 'Live Sustainably',
        'subtitle': 'Track your carbon footprint and make eco-friendly choices.',
        'icon': Icons.eco,
        'color': AppColors.primary,
        'route': '/carbon-footprint',
      },
      {
        'title': 'Reduce Waste',
        'subtitle': 'Monitor and reduce your daily waste for a cleaner planet.',
        'icon': Icons.recycling,
        'color': AppColors.success,
        'route': '/waste-tracker',
      },
      {
        'title': 'Save Energy',
        'subtitle': 'Discover tips to save energy and lower your carbon impact.',
        'icon': Icons.lightbulb,
        'color': AppColors.warning,
        'route': '/energy-tips',
      },
      {
        'title': 'Shop Green',
        'subtitle': 'Find eco-friendly products and support sustainable brands.',
        'icon': Icons.shopping_bag,
        'color': AppColors.info,
        'route': '/search',
      },
      {
        'title': 'Join Challenges',
        'subtitle': 'Participate in sustainability challenges and earn rewards.',
        'icon': Icons.emoji_events,
        'color': AppColors.secondary,
        'route': '/challenges',
      },
    ];

    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: height,
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: isMobile ? 0.85 : 0.7,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            onPageChanged: (index, reason) {
              setState(() {
                _currentCarouselIndex = index;
              });
            },
          ),
          items: slides.map((slide) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
                    onTap: () {
                      if (slide['route'] != null) {
                        Navigator.pushNamed(context, slide['route']);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            (slide['color'] as Color).withOpacity(0.1),
                            (slide['color'] as Color).withOpacity(0.05),
                            Colors.white,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
                        border: Border.all(
                          color: (slide['color'] as Color).withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (slide['color'] as Color).withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(ResponsiveHelper.getAdaptiveSpacing(context) * 1.5),
                        child: Row(
                          children: [
                            // Icon container
                            Container(
                              width: isMobile ? 60 : 80,
                              height: isMobile ? 60 : 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    (slide['color'] as Color).withOpacity(0.2),
                                    (slide['color'] as Color).withOpacity(0.1),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (slide['color'] as Color).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                slide['icon'] as IconData,
                                size: isMobile ? 28 : 36,
                                color: slide['color'] as Color,
                              ),
                            ),
                            
                            SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 1.2),
                            
                            // Content
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    slide['title'] as String,
                                    style: TextStyle(
                                      fontSize: isMobile ? 18 : 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryText,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                                  Text(
                                    slide['subtitle'] as String,
                                    style: TextStyle(
                                      fontSize: isMobile ? 13 : 15,
                                      color: AppColors.secondaryText,
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8),
                                  // Action indicator
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4,
                                          vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: (slide['color'] as Color).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.arrow_forward,
                                              color: slide['color'] as Color,
                                              size: 14,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Explore',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: slide['color'] as Color,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
        
        // Carousel indicators
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: slides.asMap().entries.map((entry) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: entry.key == _currentCarouselIndex ? 24 : 8,
              height: 8,
              margin: EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: entry.key == _currentCarouselIndex 
                  ? AppColors.primary 
                  : AppColors.primary.withOpacity(0.3),
              ),
            );
          }).toList(),
        ),
      ],
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
        'category': 'Tracking',
        'badge': 'Popular',
      },
      {
        'title': 'Sustainable Challenges',
        'subtitle': 'Participate in eco-friendly challenges and earn rewards.',
        'icon': Icons.emoji_events,
        'route': '/challenges',
        'requiresAuth': true,
        'color': AppColors.success,
        'gradient': [AppColors.success, AppColors.success.withValues(alpha: 0.7)],
        'category': 'Engagement',
        'badge': 'New',
      },
      {
        'title': 'Waste Reduction Tracker',
        'subtitle': 'Monitor your waste reduction efforts and set goals.',
        'icon': Icons.recycling,
        'route': '/waste-tracker',
        'requiresAuth': true,
        'color': AppColors.info,
        'gradient': [AppColors.info, AppColors.info.withValues(alpha: 0.7)],
        'category': 'Tracking',
      },
      {
        'title': 'Progress Dashboard',
        'subtitle': 'View your sustainability progress and achievements.',
        'icon': Icons.analytics,
        'route': '/progress-dashboard',
        'requiresAuth': true,
        'color': AppColors.warning,
        'gradient': [AppColors.warning, AppColors.warning.withValues(alpha: 0.7)],
        'category': 'Analytics',
      },
      {
        'title': 'Green Certifications',
        'subtitle': 'Learn about eco-labels and sustainable product certifications.',
        'icon': Icons.verified,
        'route': '/certifications',
        'requiresAuth': false,
        'color': AppColors.success,
        'gradient': [AppColors.success, AppColors.success.withValues(alpha: 0.7)],
        'category': 'Education',
      },
      {
        'title': 'Energy Conservation Tips',
        'subtitle': 'Discover ways to save energy and reduce your carbon footprint.',
        'icon': Icons.lightbulb,
        'route': '/energy-tips',
        'requiresAuth': false,
        'color': AppColors.warning,
        'gradient': [AppColors.warning, AppColors.warning.withValues(alpha: 0.7)],
        'category': 'Tips',
      },
      {
        'title': 'Eco-Travel Guide',
        'subtitle': 'Find sustainable travel options and eco-friendly destinations.',
        'icon': Icons.travel_explore,
        'route': '/eco-travel',
        'requiresAuth': false,
        'color': AppColors.info,
        'gradient': [AppColors.info, AppColors.info.withValues(alpha: 0.7)],
        'category': 'Travel',
      },
      {
        'title': 'Educational Content',
        'subtitle': 'Read articles and watch videos about sustainability.',
        'icon': Icons.school,
        'route': '/educational-content',
        'requiresAuth': false,
        'color': AppColors.primary,
        'gradient': [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
        'category': 'Education',
      },
      {
        'title': 'Sustainable Recipes',
        'subtitle': 'Cook delicious meals with eco-friendly ingredients.',
        'icon': Icons.restaurant,
        'route': '/recipes',
        'requiresAuth': false,
        'color': AppColors.success,
        'gradient': [AppColors.success, AppColors.success.withValues(alpha: 0.7)],
        'category': 'Lifestyle',
      },
      {
        'title': 'Community Forum',
        'subtitle': 'Connect with others and share your sustainability journey.',
        'icon': Icons.forum,
        'route': '/forum',
        'requiresAuth': true,
        'color': AppColors.info,
        'gradient': [AppColors.info, AppColors.info.withValues(alpha: 0.7)],
        'category': 'Community',
      },
      {
        'title': 'Image Gallery',
        'subtitle': 'Browse inspiring images of sustainable living.',
        'icon': Icons.photo_library,
        'route': '/gallery',
        'requiresAuth': false,
        'color': AppColors.warning,
        'gradient': [AppColors.warning, AppColors.warning.withValues(alpha: 0.7)],
        'category': 'Inspiration',
      },
      {
        'title': 'Eco-Friendly Products',
        'subtitle': 'Shop for sustainable products and green alternatives.',
        'icon': Icons.shopping_bag,
        'route': '/search',
        'requiresAuth': false,
        'color': AppColors.primary,
        'gradient': [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
        'category': 'Shopping',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enhanced header section
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.getAdaptiveSpacing(context),
            vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 1.5,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withOpacity(0.05),
                AppColors.secondary.withOpacity(0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context)),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.explore,
                      color: AppColors.primary,
                      size: ResponsiveHelper.getAdaptiveIconSize(context),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Explore Features',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getTitleFontSize(context),
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Discover tools and resources to enhance your sustainable lifestyle',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getBodyFontSize(context),
                            color: AppColors.secondaryText,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 1.5),
        
        // Enhanced feature grid
        ResponsiveHelper.isMobile(context) 
          ? _buildMobileFeatureGrid(context, features, AuthService.getCurrentUserId())
          : _buildDesktopFeatureGrid(context, features, AuthService.getCurrentUserId()),
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
        return _buildEnhancedFeatureCard(context, feature, currentUserId, index);
      },
    );
  }

  Widget _buildEnhancedFeatureCard(BuildContext context, Map<String, dynamic> feature, String? currentUserId, int index) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final hasBadge = feature['badge'] != null;
    final requiresAuth = feature['requiresAuth'] as bool;
    final isLocked = requiresAuth && currentUserId == null;
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _handleFeatureNavigation(context, feature),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: (feature['color'] as Color).withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight.withOpacity(0.08),
                blurRadius: 16,
                offset: Offset(0, 6),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: (feature['color'] as Color).withOpacity(0.03),
                blurRadius: 8,
                offset: Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        (feature['color'] as Color).withOpacity(0.02),
                        Colors.transparent,
                        (feature['color'] as Color).withOpacity(0.01),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Badge
              if (hasBadge)
                Positioned(
                  top: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5,
                  right: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4,
                      vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2,
                    ),
                    decoration: BoxDecoration(
                      color: feature['badge'] == 'Popular' 
                        ? AppColors.warning 
                        : AppColors.success,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (feature['badge'] == 'Popular' 
                            ? AppColors.warning 
                            : AppColors.success).withOpacity(0.3),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      feature['badge'] as String,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getBodyFontSize(context) * 0.7,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              
              // Main content
              Padding(
                padding: EdgeInsets.all(ResponsiveHelper.getAdaptiveSpacing(context) * 1.2),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min, // Still keep min for safety
                    children: [
                      // Category label
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4,
                          vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2,
                        ),
                        decoration: BoxDecoration(
                          color: (feature['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          feature['category'] as String,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getBodyFontSize(context) * 0.7,
                            fontWeight: FontWeight.w600,
                            color: feature['color'] as Color,
                          ),
                        ),
                      ),
                      
                      SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                      
                      // Icon container with enhanced design
                      Container(
                        padding: EdgeInsets.all(ResponsiveHelper.getAdaptiveSpacing(context) * 1.2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              (feature['color'] as Color).withOpacity(0.15),
                              (feature['color'] as Color).withOpacity(0.08),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (feature['color'] as Color).withOpacity(0.2),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          feature['icon'] as IconData,
                          color: feature['color'] as Color,
                          size: ResponsiveHelper.getAdaptiveIconSize(context) * 1.4,
                        ),
                      ),
                      
                      SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 1.2),
                      
                      // Title with enhanced typography
                      Text(
                        feature['title'] as String,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getSubtitleFontSize(context),
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                          height: 1.2,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                      
                      // Subtitle with improved readability
                      Text(
                        feature['subtitle'] as String,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getBodyFontSize(context) * 0.9,
                          color: AppColors.secondaryText,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8),
                      
                      // Action indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isLocked)
                            Icon(
                              Icons.lock,
                              color: AppColors.mutedText,
                              size: ResponsiveHelper.getCompactIconSize(context),
                            )
                          else
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4,
                                vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2,
                              ),
                              decoration: BoxDecoration(
                                color: (feature['color'] as Color).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_forward,
                                    color: feature['color'] as Color,
                                    size: ResponsiveHelper.getCompactIconSize(context) * 0.8,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Explore',
                                    style: TextStyle(
                                      fontSize: ResponsiveHelper.getBodyFontSize(context) * 0.7,
                                      fontWeight: FontWeight.w600,
                                      color: feature['color'] as Color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileFeatureGrid(BuildContext context, List<Map<String, dynamic>> features, String? currentUserId) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.95,
        crossAxisSpacing: ResponsiveHelper.getAdaptiveSpacing(context),
        mainAxisSpacing: ResponsiveHelper.getAdaptiveSpacing(context),
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        // Only show admin features if user is admin
        if (feature['adminOnly'] == true && _userRole != 'admin') {
          return const SizedBox.shrink();
        }
        return _buildEnhancedFeatureCard(context, feature, currentUserId, index);
      },
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
        // Only show admin features if user is admin
        if (feature['adminOnly'] == true && _userRole != 'admin') {
          return const SizedBox.shrink();
        }
        return _buildEnhancedFeatureCard(context, feature, currentUserId, index);
      },
    );
  }

  void _handleFeatureNavigation(BuildContext context, Map<String, dynamic> feature) {
    if (feature['adminOnly'] == true && _userRole != 'admin') {
      // Optionally show a message or do nothing
      return;
    }
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


