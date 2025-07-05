import 'package:flutter/material.dart';
import 'package:living/style/theme.dart';
import 'package:living/services/user_dao.dart';
import 'package:living/services/auth_helper.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  Future<String?> _getUserRole() async {
    final user = AuthService().currentUser;
    if (user == null) return null;
    return await UserDao().getUserRole(user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      color: const Color.fromARGB(255, 24, 70, 72),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Builder(
            builder:
                (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  color: moonstone,
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
                  width: 150,
                  height: 50,
                  fit: BoxFit.fill,
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            color: moonstone,
            onPressed: () {
              Navigator.pushNamed(context, '/wishlist');
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            color: moonstone,
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            color: moonstone,
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

    return Drawer(
      child:
          user == null
              ? ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(color: blackberry),
                    child: Center(
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/logo.png',
                            width: 200,
                            height: 100,
                            fit: BoxFit.fill,
                          ),
                        ],
                      ),
                    ),
                  ),
                  ...DrawerItems.guestItems.map(
                    (item) => ListTile(
                      leading: Icon(item.icon, color: blackberry),
                      title: Text(item.label),
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
                    return const Center(child: CircularProgressIndicator());
                  }
                  final isAdmin = snapshot.data == 'admin';
                  final drawerItems =
                      isAdmin ? DrawerItems.adminItems : DrawerItems.userItems;
                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      DrawerHeader(
                        decoration: const BoxDecoration(color: blackberry),
                        child: Center(
                          child: Text(
                            'Living'.toUpperCase(),
                            style: const TextStyle(
                              color: moonstone,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      ...drawerItems.map(
                        (item) => ListTile(
                          leading: Icon(item.icon, color: blackberry),
                          title: Text(item.label),
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
