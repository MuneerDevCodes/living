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
    final headerHeight = ResponsiveHelper.getScreenHeight(context) * 0.08;
    final logoWidth = ResponsiveHelper.getScreenWidth(context) * 0.25;
    final logoHeight = headerHeight * 0.7;
    
    return Container(
      height: headerHeight,
      color: AppColors.headerBackground,
      padding: ResponsiveHelper.getHorizontalPadding(context),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(
                Icons.menu,
                size: ResponsiveHelper.getAdaptiveIconSize(context),
              ),
              color: AppColors.secondary,
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/');
            },
            child: Row(
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: logoWidth,
                  height: logoHeight,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.favorite_border,
              size: ResponsiveHelper.getAdaptiveIconSize(context),
            ),
            color: AppColors.secondary,
            onPressed: () {
              Navigator.pushNamed(context, '/wishlist');
            },
          ),
          IconButton(
            icon: Icon(
              Icons.shopping_cart_outlined,
              size: ResponsiveHelper.getAdaptiveIconSize(context),
            ),
            color: AppColors.secondary,
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
          IconButton(
            icon: Icon(
              Icons.logout,
              size: ResponsiveHelper.getAdaptiveIconSize(context),
            ),
            color: AppColors.secondary,
            onPressed: () {
              Navigator.pushNamed(context, '/logout');
            },
          ),
        ],
      ),
    );
  }

  // Method to build the drawer - call this from your main screen
  static Widget buildDrawer(BuildContext context) {
    final user = AuthService().currentUser;
  //  final drawerHeaderHeight = ResponsiveHelper.getScreenHeight(context) * 0.25;
    final logoSize = ResponsiveHelper.getAdaptiveImageSize(context) * 2;

    return Drawer(
      child: user == null
          ? ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: AppColors.primary),
                  child: Center(
                    child: Padding(
                      padding: ResponsiveHelper.getAdaptivePadding(context),
                      child: Image.asset(
                        'assets/logo.png',
                        width: logoSize,
                        height: logoSize * 0.5,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                ...DrawerItems.guestItems.map(
                  (item) => ListTile(
                    leading: Icon(
                      item.icon,
                      color: AppColors.primary,
                      size: ResponsiveHelper.getAdaptiveIconSize(context),
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, item.route);
                    },
                  ),
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
                          child: Text(
                            'Living'.toUpperCase(),
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 22),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    ...drawerItems.map(
                      (item) => ListTile(
                        leading: Icon(
                          item.icon,
                          color: AppColors.primary,
                          size: ResponsiveHelper.getAdaptiveIconSize(context),
                        ),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, item.route);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class DrawerItems {
  static final List<_DrawerItem> adminItems = [
    // Informational
    _DrawerItem(label: 'About Us', icon: Icons.info, route: '/about-us'),
    _DrawerItem(
      label: 'Contact Us',
      icon: Icons.support_agent,
      route: '/contact-us',
    ),
    _DrawerItem(label: 'FAQ', icon: Icons.help_outline, route: '/faq'),

    // User Features
    _DrawerItem(label: 'Cart', icon: Icons.shopping_cart, route: '/cart'),
    _DrawerItem(
      label: 'Wishlist',
      icon: Icons.favorite_border,
      route: '/wishlist',
    ),
    _DrawerItem(label: 'Order', icon: Icons.receipt_long, route: '/order'),
    _DrawerItem(
      label: 'Profile',
      icon: Icons.account_circle_outlined,
      route: '/profile',
    ),

    // Admin Management
    _DrawerItem(
      label: 'Manage Products',
      icon: Icons.inventory,
      route: '/manage-products',
    ),
    _DrawerItem(
      label: 'Manage Categories',
      icon: Icons.category,
      route: '/manage-categories',
    ),
    _DrawerItem(
      label: 'Manage Orders',
      icon: Icons.rule_folder,
      route: '/manage-orders',
    ),
    _DrawerItem(
      label: 'Manage Contact Us',
      icon: Icons.mark_email_read,
      route: '/manage-contact-us',
    ),
    _DrawerItem(
      label: 'Manage Challenges',
      icon: Icons.emoji_events,
      route: '/manage-challenges',
    ),
    _DrawerItem(
      label: 'Manage Educational Content',
      icon: Icons.school,
      route: '/manage-educational-content',
    ),
  ];

  static final List<_DrawerItem> userItems = [
    // Informational
    _DrawerItem(label: 'About Us', icon: Icons.info, route: '/about-us'),
    _DrawerItem(
      label: 'Contact Us',
      icon: Icons.support_agent,
      route: '/contact-us',
    ),
    _DrawerItem(label: 'FAQ', icon: Icons.help_outline, route: '/faq'),

    // User Features
    _DrawerItem(label: 'Cart', icon: Icons.shopping_cart, route: '/cart'),
    _DrawerItem(
      label: 'Wishlist',
      icon: Icons.favorite_border,
      route: '/wishlist',
    ),
    _DrawerItem(label: 'Order', icon: Icons.receipt_long, route: '/order'),
    _DrawerItem(
      label: 'Profile',
      icon: Icons.account_circle_outlined,
      route: '/profile',
    ),
  ];

  static final List<_DrawerItem> guestItems = [
    // Informational
    _DrawerItem(label: 'About Us', icon: Icons.info, route: '/about-us'),
    _DrawerItem(
      label: 'Contact Us',
      icon: Icons.support_agent,
      route: '/contact-us',
    ),
    _DrawerItem(label: 'FAQ', icon: Icons.help_outline, route: '/faq'),

    // Action
    _DrawerItem(label: 'Login', icon: Icons.login, route: '/auth'),
  ];
}

class _DrawerItem {
  final String label;
  final IconData icon;
  final String route;

  const _DrawerItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}
