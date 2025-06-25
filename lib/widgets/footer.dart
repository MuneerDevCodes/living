// lib/BookstoreFooter.dart
import 'package:flutter/material.dart';
import 'package:living/style/theme.dart';

class BookstoreFooter extends StatelessWidget {
  const BookstoreFooter({super.key});

  @override
  Widget build(BuildContext context) {
    // Helper for icon + label
    Widget navItem({
      required IconData icon,
      required String label,
      required String route,
      bool active = false,
    }) {
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pushNamed(context, route);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: active ? Colors.white : moonstone, size: 26),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: active ? Colors.white : moonstone,
                    fontSize: 12,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: blackberry,
        border: Border(
          top: BorderSide(
            color: moonstone.withAlpha((0.18 * 255).toInt()),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: blackberry.withAlpha((0.08 * 255).toInt()),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            navItem(
              icon: Icons.home,
              label: 'Home',
              route: '/',
              active: ModalRoute.of(context)?.settings.name == '/',
            ),
            navItem(
              icon: Icons.search,
              label: 'Search',
              route: '/search',
              active: ModalRoute.of(context)?.settings.name == '/search',
            ),
            navItem(
              icon: Icons.person,
              label: 'Profile',
              route: '/profile',
              active: ModalRoute.of(context)?.settings.name == '/profile',
            ),
          ],
        ),
      ),
    );
  }
}
