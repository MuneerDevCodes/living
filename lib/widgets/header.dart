import 'package:flutter/material.dart';
import 'package:living/style/theme.dart';
import 'package:living/services/user_dao.dart';
import 'package:living/services/auth_helper.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/widgets/loader.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  Future<String?> _getUserRole() async {
    final user = AuthService().currentUser;
    if (user == null) return null;
    return await UserDao().getUserRole(user.uid);
  }

  @override
  Widget build(BuildContext context) {
    final headerHeight = ResponsiveHelper.getHeaderFooterHeight(context);
    final screenWidth = ResponsiveHelper.getScreenWidth(context);
    
    // Improved responsive logo sizing
    final logoWidth = ResponsiveHelper.isMobile(context) 
        ? screenWidth * 0.08 // Smaller for mobile
        : ResponsiveHelper.isTablet(context)
            ? screenWidth * 0.06 // Medium for tablet
            : screenWidth * 0.05; // Smaller for desktop
    final logoHeight = headerHeight * 0.5; // Reduced height
    
    return Container(
      height: headerHeight,
      decoration: BoxDecoration(
        color: AppColors.headerBackground,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: ResponsiveHelper.getHorizontalPadding(context),
      child: Row(
        children: [
          // Menu button - only on mobile
          if (ResponsiveHelper.isMobile(context))
            Container(
              margin: EdgeInsets.only(right: ResponsiveHelper.getAdaptiveGap(context) * 0.5),
              child: Builder(
                builder: (context) => IconButton(
                  icon: Icon(
                    Icons.menu,
                    size: ResponsiveHelper.getCompactIconSize(context),
                  ),
                  color: AppColors.white,
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
            ),
          
          // Enhanced Logo section with better positioning
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/');
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo container with better styling
                  Container(
                    padding: EdgeInsets.all(ResponsiveHelper.getAdaptiveGap(context) * 0.3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    child: Semantics(
                      label: 'Living App Logo',
                      image: true,
                      child: Image.asset(
                        'assets/logo.png',
                        width: logoWidth,
                        height: logoHeight,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: logoWidth,
                            height: logoHeight,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.eco,
                              size: logoHeight * 0.4,
                              color: AppColors.primary,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // App name with improved styling
                  Padding(
                    padding: EdgeInsets.only(left: ResponsiveHelper.getAdaptiveGap(context) * 0.5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Planet Care',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: ResponsiveHelper.isMobile(context) 
                                ? ResponsiveHelper.getBodyFontSize(context) * 1.1
                                : ResponsiveHelper.getSubtitleFontSize(context),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        if (ResponsiveHelper.isDesktop(context))
                          Text(
                            'Sustainable Living Guide',
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.8),
                              fontSize: ResponsiveHelper.getBodyFontSize(context) * 0.7,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Action buttons - properly aligned to the right
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (ResponsiveHelper.isMobile(context)) {
      return _buildMobileActions(context);
    } else if (ResponsiveHelper.isTablet(context)) {
      return _buildTabletActions(context);
    } else {
      return _buildDesktopActions(context);
    }
  }

  Widget _buildMobileActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMobileActionButton(
          context,
          icon: Icons.favorite_border,
          onPressed: () => Navigator.pushNamed(context, '/wishlist'),
        ),
        SizedBox(width: ResponsiveHelper.getAdaptiveGap(context) * 0.3),
        _buildMobileActionButton(
          context,
          icon: Icons.shopping_cart_outlined,
          onPressed: () => Navigator.pushNamed(context, '/cart'),
        ),
        SizedBox(width: ResponsiveHelper.getAdaptiveGap(context) * 0.3),
        _buildMobileActionButton(
          context,
          icon: AuthService().currentUser != null ? Icons.logout : Icons.login,
          onPressed: () => Navigator.pushNamed(
            context, 
            AuthService().currentUser != null ? '/logout' : '/auth'
          ),
        ),
      ],
    );
  }

  Widget _buildTabletActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTabletActionButton(
          context,
          icon: Icons.favorite_border,
          label: 'Wishlist',
          onPressed: () => Navigator.pushNamed(context, '/wishlist'),
        ),
        SizedBox(width: ResponsiveHelper.getAdaptiveGap(context) * 0.5),
        _buildTabletActionButton(
          context,
          icon: Icons.shopping_cart_outlined,
          label: 'Cart',
          onPressed: () => Navigator.pushNamed(context, '/cart'),
        ),
        SizedBox(width: ResponsiveHelper.getAdaptiveGap(context) * 0.5),
        _buildTabletActionButton(
          context,
          icon: AuthService().currentUser != null ? Icons.logout : Icons.login,
          label: AuthService().currentUser != null ? 'Logout' : 'Login',
          onPressed: () => Navigator.pushNamed(
            context, 
            AuthService().currentUser != null ? '/logout' : '/auth'
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDesktopActionButton(
          context,
          icon: Icons.favorite_border,
          label: 'Wishlist',
          onPressed: () => Navigator.pushNamed(context, '/wishlist'),
        ),
        SizedBox(width: ResponsiveHelper.getAdaptiveGap(context) * 0.5),
        _buildDesktopActionButton(
          context,
          icon: Icons.shopping_cart_outlined,
          label: 'Cart',
          onPressed: () => Navigator.pushNamed(context, '/cart'),
        ),
        SizedBox(width: ResponsiveHelper.getAdaptiveGap(context) * 0.5),
        _buildDesktopActionButton(
          context,
          icon: AuthService().currentUser != null ? Icons.logout : Icons.login,
          label: AuthService().currentUser != null ? 'Logout' : 'Login',
          onPressed: () => Navigator.pushNamed(
            context, 
            AuthService().currentUser != null ? '/logout' : '/auth'
          ),
        ),
      ],
    );
  }

  Widget _buildMobileActionButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(
        icon,
        size: ResponsiveHelper.getCompactIconSize(context),
      ),
      color: AppColors.white,
      onPressed: onPressed,
      padding: EdgeInsets.all(ResponsiveHelper.getAdaptiveGap(context) * 0.3),
      constraints: BoxConstraints(
        minWidth: ResponsiveHelper.getButtonHeight(context) * 0.6,
        minHeight: ResponsiveHelper.getButtonHeight(context) * 0.6,
      ),
    );
  }

  Widget _buildTabletActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: ResponsiveHelper.getAdaptiveIconSize(context),
        color: AppColors.white,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: AppColors.white,
          fontSize: ResponsiveHelper.getBodyFontSize(context) * 0.9,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5,
          vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getAdaptiveBorderRadius(context),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: ResponsiveHelper.getAdaptiveIconSize(context),
        color: AppColors.white,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: AppColors.white,
          fontSize: ResponsiveHelper.getBodyFontSize(context) * 0.9,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5,
          vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getAdaptiveBorderRadius(context),
          ),
        ),
      ),
    );
  }

  // Method to build the drawer - call this from your main screen
  static Widget buildDrawer(BuildContext context) {
    final user = AuthService().currentUser;
    final logoSize = ResponsiveHelper.getAdaptiveImageSize(context) * 2;
    final drawerWidth = ResponsiveHelper.getDrawerWidth(context);

    return Drawer(
      width: drawerWidth,
      child: user == null
          ? ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: AppColors.primary),
                  child: Center(
                    child: Padding(
                      padding: ResponsiveHelper.getAdaptivePadding(context),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/logo.png',
                            width: logoSize,
                            height: logoSize * 0.5,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(height: ResponsiveHelper.getAdaptiveGap(context)),
                          Text(
                            'Living App',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: ResponsiveHelper.getSubtitleFontSize(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ...DrawerItems.guestItems.map(
                  (item) => _buildDrawerItem(context, item),
                ),
              ],
            )
          : FutureBuilder<String?>(
              future: Header()._getUserRole(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: Loader());
                }
                final isAdmin = snapshot.data == 'admin';
                final drawerItems =
                    isAdmin ? DrawerItems.adminItems : DrawerItems.userItems;
                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    DrawerHeader(
                      decoration: const BoxDecoration(color: AppColors.primary),
                      child: Center(
                        child: Padding(
                          padding: ResponsiveHelper.getAdaptivePadding(context),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Living'.toUpperCase(),
                                style: TextStyle(
                                  color: AppColors.secondary,
                                  fontSize: ResponsiveHelper.getTitleFontSize(context),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: ResponsiveHelper.getAdaptiveGap(context)),
                              Text(
                                isAdmin ? 'Administrator' : 'User',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: ResponsiveHelper.getBodyFontSize(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ...drawerItems.map(
                      (item) => _buildDrawerItem(context, item),
                    ),
                  ],
                );
              },
            ),
    );
  }

  static Widget _buildDrawerItem(BuildContext context, DrawerItem item) {
    return ListTile(
      leading: Icon(
        item.icon,
        color: AppColors.primary,
        size: ResponsiveHelper.getAdaptiveIconSize(context),
      ),
      title: Text(
        item.label,
        style: TextStyle(
          fontSize: ResponsiveHelper.getBodyFontSize(context),
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, item.route);
      },
    );
  }
}

class DrawerItems {
  static final List<DrawerItem> adminItems = [
    // Informational
    DrawerItem(label: 'About Us', icon: Icons.info, route: '/about-us'),
    DrawerItem(label: 'FAQ', icon: Icons.help, route: '/faq'),
    DrawerItem(label: 'Contact Us', icon: Icons.contact_support, route: '/contact-us'),
    
    // User Features
    DrawerItem(label: 'Carbon Footprint', icon: Icons.cloud, route: '/carbon-footprint'),
    DrawerItem(label: 'Challenges', icon: Icons.emoji_events, route: '/challenges'),
    DrawerItem(label: 'Waste Tracker', icon: Icons.recycling, route: '/waste-tracker'),
    DrawerItem(label: 'Progress Dashboard', icon: Icons.analytics, route: '/progress-dashboard'),
    DrawerItem(label: 'Certifications', icon: Icons.verified, route: '/certifications'),
    DrawerItem(label: 'Energy Tips', icon: Icons.lightbulb, route: '/energy-tips'),
    DrawerItem(label: 'Eco Travel', icon: Icons.travel_explore, route: '/eco-travel'),
    DrawerItem(label: 'Educational Content', icon: Icons.school, route: '/educational-content'),
    DrawerItem(label: 'Recipes', icon: Icons.restaurant, route: '/recipes'),
    DrawerItem(label: 'Forum', icon: Icons.forum, route: '/forum'),
    DrawerItem(label: 'Gallery', icon: Icons.photo_library, route: '/gallery'),
    DrawerItem(label: 'Search Products', icon: Icons.search, route: '/search'),
    DrawerItem(label: 'Cart', icon: Icons.shopping_cart, route: '/cart'),
    DrawerItem(label: 'Orders', icon: Icons.receipt, route: '/orders'),
    DrawerItem(label: 'Wishlist', icon: Icons.favorite, route: '/wishlist'),
    DrawerItem(label: 'Profile', icon: Icons.person, route: '/profile'),
    DrawerItem(label: 'Settings', icon: Icons.settings, route: '/settings'),
    
    // Admin Features
    DrawerItem(label: 'Manage Categories', icon: Icons.category, route: '/manage-categories'),
    DrawerItem(label: 'Manage Products', icon: Icons.inventory, route: '/manage-products'),
    DrawerItem(label: 'Manage Orders', icon: Icons.assignment, route: '/manage-orders'),
    DrawerItem(label: 'Manage Challenges', icon: Icons.emoji_events, route: '/manage-challenges'),
    DrawerItem(label: 'Manage Educational Content', icon: Icons.article, route: '/manage-educational-content'),
    DrawerItem(label: 'Manage Contact Us', icon: Icons.support_agent, route: '/manage-contact-us'),
  ];

  static final List<DrawerItem> userItems = [
    // Informational
    DrawerItem(label: 'About Us', icon: Icons.info, route: '/about-us'),
    DrawerItem(label: 'FAQ', icon: Icons.help, route: '/faq'),
    DrawerItem(label: 'Contact Us', icon: Icons.contact_support, route: '/contact-us'),
    
    // User Features
    DrawerItem(label: 'Carbon Footprint', icon: Icons.cloud, route: '/carbon-footprint'),
    DrawerItem(label: 'Challenges', icon: Icons.emoji_events, route: '/challenges'),
    DrawerItem(label: 'Waste Tracker', icon: Icons.recycling, route: '/waste-tracker'),
    DrawerItem(label: 'Progress Dashboard', icon: Icons.analytics, route: '/progress-dashboard'),
    DrawerItem(label: 'Certifications', icon: Icons.verified, route: '/certifications'),
    DrawerItem(label: 'Energy Tips', icon: Icons.lightbulb, route: '/energy-tips'),
    DrawerItem(label: 'Eco Travel', icon: Icons.travel_explore, route: '/eco-travel'),
    DrawerItem(label: 'Educational Content', icon: Icons.school, route: '/educational-content'),
    DrawerItem(label: 'Recipes', icon: Icons.restaurant, route: '/recipes'),
    DrawerItem(label: 'Forum', icon: Icons.forum, route: '/forum'),
    DrawerItem(label: 'Gallery', icon: Icons.photo_library, route: '/gallery'),
    DrawerItem(label: 'Search Products', icon: Icons.search, route: '/search'),
    DrawerItem(label: 'Cart', icon: Icons.shopping_cart, route: '/cart'),
    DrawerItem(label: 'Orders', icon: Icons.receipt, route: '/orders'),
    DrawerItem(label: 'Wishlist', icon: Icons.favorite, route: '/wishlist'),
    DrawerItem(label: 'Profile', icon: Icons.person, route: '/profile'),
    DrawerItem(label: 'Settings', icon: Icons.settings, route: '/settings'),
  ];

  static final List<DrawerItem> guestItems = [
    // Informational
    DrawerItem(label: 'About Us', icon: Icons.info, route: '/about-us'),
    DrawerItem(label: 'FAQ', icon: Icons.help, route: '/faq'),
    DrawerItem(label: 'Contact Us', icon: Icons.contact_support, route: '/contact-us'),
    
    // Public Features
    DrawerItem(label: 'Certifications', icon: Icons.verified, route: '/certifications'),
    DrawerItem(label: 'Energy Tips', icon: Icons.lightbulb, route: '/energy-tips'),
    DrawerItem(label: 'Eco Travel', icon: Icons.travel_explore, route: '/eco-travel'),
    DrawerItem(label: 'Educational Content', icon: Icons.school, route: '/educational-content'),
    DrawerItem(label: 'Recipes', icon: Icons.restaurant, route: '/recipes'),
    DrawerItem(label: 'Gallery', icon: Icons.photo_library, route: '/gallery'),
    DrawerItem(label: 'Search Products', icon: Icons.search, route: '/search'),
    
    // Auth
    DrawerItem(label: 'Login/Register', icon: Icons.login, route: '/auth'),
  ];
}

class DrawerItem {
  final String label;
  final IconData icon;
  final String route;

  DrawerItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}
