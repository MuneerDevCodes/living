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
    final logoWidth = ResponsiveHelper.isMobile(context) 
        ? ResponsiveHelper.getScreenWidth(context) * 0.3
        : ResponsiveHelper.getScreenWidth(context) * 0.2;
    final logoHeight = headerHeight * 0.6;
    
    return Container(
      height: headerHeight,
      color: AppColors.headerBackground,
      padding: ResponsiveHelper.getHorizontalPadding(context),
      child: Row(
        children: [
          // Menu button - always visible on mobile, hidden on larger screens
          if (ResponsiveHelper.isMobile(context))
            Builder(
              builder: (context) => IconButton(
                icon: Icon(
                  Icons.menu,
                  size: ResponsiveHelper.getAdaptiveIconSize(context),
                ),
                color: AppColors.white,
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
          
          // Logo
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/');
            },
            child: Row(
              children: [
                Semantics(
                  label: 'Living App Logo',
                  image: true,
                  child: Image.asset(
                    'assets/logo.png',
                    width: logoWidth,
                    height: logoHeight,
                    fit: BoxFit.contain,
                  ),
                ),
                if (!ResponsiveHelper.isMobile(context))
                  Padding(
                    padding: EdgeInsets.only(left: ResponsiveHelper.getAdaptiveGap(context)),
                    child: Text(
                      'Living',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: ResponsiveHelper.getSubtitleFontSize(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Action buttons - responsive layout
          if (ResponsiveHelper.isMobile(context))
            _buildMobileActions(context)
          else
            _buildDesktopActions(context),
        ],
      ),
    );
  }

  Widget _buildMobileActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            Icons.favorite_border,
            size: ResponsiveHelper.getAdaptiveIconSize(context),
          ),
          color: AppColors.white,
          onPressed: () {
            Navigator.pushNamed(context, '/wishlist');
          },
        ),
        IconButton(
          icon: Icon(
            Icons.shopping_cart_outlined,
            size: ResponsiveHelper.getAdaptiveIconSize(context),
          ),
          color: AppColors.white,
          onPressed: () {
            Navigator.pushNamed(context, '/cart');
          },
        ),
        IconButton(
          icon: Icon(
            Icons.logout,
            size: ResponsiveHelper.getAdaptiveIconSize(context),
          ),
          color: AppColors.white,
          onPressed: () {
            Navigator.pushNamed(context, '/logout');
          },
        ),
      ],
    );
  }

  Widget _buildDesktopActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          context,
          icon: Icons.favorite_border,
          label: 'Wishlist',
          onPressed: () => Navigator.pushNamed(context, '/wishlist'),
        ),
        SizedBox(width: ResponsiveHelper.getAdaptiveGap(context)),
        _buildActionButton(
          context,
          icon: Icons.shopping_cart_outlined,
          label: 'Cart',
          onPressed: () => Navigator.pushNamed(context, '/cart'),
        ),
        SizedBox(width: ResponsiveHelper.getAdaptiveGap(context)),
        _buildActionButton(
          context,
          icon: Icons.logout,
          label: 'Logout',
          onPressed: () => Navigator.pushNamed(context, '/logout'),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    if (ResponsiveHelper.isTablet(context)) {
      return IconButton(
        icon: Icon(icon, size: ResponsiveHelper.getAdaptiveIconSize(context)),
        color: AppColors.white,
        onPressed: onPressed,
      );
    } else {
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
            fontSize: ResponsiveHelper.getBodyFontSize(context),
          ),
        ),
      );
    }
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

  static Widget _buildDrawerItem(BuildContext context, _DrawerItem item) {
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
  static final List<_DrawerItem> adminItems = [
    // Informational
    _DrawerItem(label: 'About Us', icon: Icons.info, route: '/about-us'),
    _DrawerItem(label: 'FAQ', icon: Icons.help, route: '/faq'),
    _DrawerItem(label: 'Contact Us', icon: Icons.contact_support, route: '/contact-us'),
    
    // User Features
    _DrawerItem(label: 'Carbon Footprint', icon: Icons.cloud, route: '/carbon-footprint'),
    _DrawerItem(label: 'Challenges', icon: Icons.emoji_events, route: '/challenges'),
    _DrawerItem(label: 'Waste Tracker', icon: Icons.recycling, route: '/waste-tracker'),
    _DrawerItem(label: 'Progress Dashboard', icon: Icons.analytics, route: '/progress-dashboard'),
    _DrawerItem(label: 'Certifications', icon: Icons.verified, route: '/certifications'),
    _DrawerItem(label: 'Energy Tips', icon: Icons.lightbulb, route: '/energy-tips'),
    _DrawerItem(label: 'Eco Travel', icon: Icons.travel_explore, route: '/eco-travel'),
    _DrawerItem(label: 'Educational Content', icon: Icons.school, route: '/educational-content'),
    _DrawerItem(label: 'Recipes', icon: Icons.restaurant, route: '/recipes'),
    _DrawerItem(label: 'Forum', icon: Icons.forum, route: '/forum'),
    _DrawerItem(label: 'Gallery', icon: Icons.photo_library, route: '/gallery'),
    _DrawerItem(label: 'Search Products', icon: Icons.search, route: '/search'),
    _DrawerItem(label: 'Cart', icon: Icons.shopping_cart, route: '/cart'),
    _DrawerItem(label: 'Orders', icon: Icons.receipt, route: '/orders'),
    _DrawerItem(label: 'Wishlist', icon: Icons.favorite, route: '/wishlist'),
    _DrawerItem(label: 'Profile', icon: Icons.person, route: '/profile'),
    
    // Admin Features
    _DrawerItem(label: 'Manage Categories', icon: Icons.category, route: '/manage-categories'),
    _DrawerItem(label: 'Manage Products', icon: Icons.inventory, route: '/manage-products'),
    _DrawerItem(label: 'Manage Orders', icon: Icons.assignment, route: '/manage-orders'),
    _DrawerItem(label: 'Manage Challenges', icon: Icons.emoji_events, route: '/manage-challenges'),
    _DrawerItem(label: 'Manage Educational Content', icon: Icons.article, route: '/manage-educational-content'),
    _DrawerItem(label: 'Manage Contact Us', icon: Icons.support_agent, route: '/manage-contact-us'),
  ];

  static final List<_DrawerItem> userItems = [
    // Informational
    _DrawerItem(label: 'About Us', icon: Icons.info, route: '/about-us'),
    _DrawerItem(label: 'FAQ', icon: Icons.help, route: '/faq'),
    _DrawerItem(label: 'Contact Us', icon: Icons.contact_support, route: '/contact-us'),
    
    // User Features
    _DrawerItem(label: 'Carbon Footprint', icon: Icons.cloud, route: '/carbon-footprint'),
    _DrawerItem(label: 'Challenges', icon: Icons.emoji_events, route: '/challenges'),
    _DrawerItem(label: 'Waste Tracker', icon: Icons.recycling, route: '/waste-tracker'),
    _DrawerItem(label: 'Progress Dashboard', icon: Icons.analytics, route: '/progress-dashboard'),
    _DrawerItem(label: 'Certifications', icon: Icons.verified, route: '/certifications'),
    _DrawerItem(label: 'Energy Tips', icon: Icons.lightbulb, route: '/energy-tips'),
    _DrawerItem(label: 'Eco Travel', icon: Icons.travel_explore, route: '/eco-travel'),
    _DrawerItem(label: 'Educational Content', icon: Icons.school, route: '/educational-content'),
    _DrawerItem(label: 'Recipes', icon: Icons.restaurant, route: '/recipes'),
    _DrawerItem(label: 'Forum', icon: Icons.forum, route: '/forum'),
    _DrawerItem(label: 'Gallery', icon: Icons.photo_library, route: '/gallery'),
    _DrawerItem(label: 'Search Products', icon: Icons.search, route: '/search'),
    _DrawerItem(label: 'Cart', icon: Icons.shopping_cart, route: '/cart'),
    _DrawerItem(label: 'Orders', icon: Icons.receipt, route: '/orders'),
    _DrawerItem(label: 'Wishlist', icon: Icons.favorite, route: '/wishlist'),
    _DrawerItem(label: 'Profile', icon: Icons.person, route: '/profile'),
  ];

  static final List<_DrawerItem> guestItems = [
    // Informational
    _DrawerItem(label: 'About Us', icon: Icons.info, route: '/about-us'),
    _DrawerItem(label: 'FAQ', icon: Icons.help, route: '/faq'),
    _DrawerItem(label: 'Contact Us', icon: Icons.contact_support, route: '/contact-us'),
    
    // Public Features
    _DrawerItem(label: 'Certifications', icon: Icons.verified, route: '/certifications'),
    _DrawerItem(label: 'Energy Tips', icon: Icons.lightbulb, route: '/energy-tips'),
    _DrawerItem(label: 'Eco Travel', icon: Icons.travel_explore, route: '/eco-travel'),
    _DrawerItem(label: 'Educational Content', icon: Icons.school, route: '/educational-content'),
    _DrawerItem(label: 'Recipes', icon: Icons.restaurant, route: '/recipes'),
    _DrawerItem(label: 'Gallery', icon: Icons.photo_library, route: '/gallery'),
    _DrawerItem(label: 'Search Products', icon: Icons.search, route: '/search'),
    
    // Auth
    _DrawerItem(label: 'Login/Register', icon: Icons.login, route: '/auth'),
  ];
}

class _DrawerItem {
  final String label;
  final IconData icon;
  final String route;

  _DrawerItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}
