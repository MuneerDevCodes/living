// lib/Footer.dart
import 'package:flutter/material.dart';
import 'package:living/style/theme.dart';
import 'package:living/style/responsive_helper.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

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
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getAdaptiveBorderRadius(context),
          ),
          onTap: () {
            Navigator.pushNamed(context, route);
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: active ? AppColors.white : AppColors.secondary,
                  size: ResponsiveHelper.getAdaptiveIconSize(context) * 0.8,
                ),
                SizedBox(height: 1),
                Text(
                  label,
                  style: TextStyle(
                    color: active ? AppColors.white : AppColors.secondary,
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 10),
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
      height: ResponsiveHelper.getHeaderFooterHeight(context),
      decoration: BoxDecoration(
        color: AppColors.footerBackground,
        border: Border(
          top: BorderSide(
            color: AppColors.secondary.withAlpha((0.18 * 255).toInt()),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha((0.08 * 255).toInt()),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
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
    );
  }
}
