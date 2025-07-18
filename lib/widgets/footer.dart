// lib/Footer.dart
import 'package:flutter/material.dart';
import 'package:living/style/theme.dart';
import 'package:living/style/responsive_helper.dart';

/// Responsive, theme-driven footer for all screen sizes.
class Footer extends StatefulWidget {
  const Footer({super.key});

  @override
  FooterState createState() => FooterState();
}

class FooterState extends State<Footer> {
  double _iconScale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _iconScale = 0.85;
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _iconScale = 1.0;
    });
  }

  void _onTapCancel() {
    setState(() {
      _iconScale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Only show footer on mobile devices
    if (!ResponsiveHelper.isMobile(context)) {
      return SizedBox.shrink();
    }

    // Helper for icon + label
    Widget navItem({
      required IconData icon,
      required String label,
      required String route,
      bool active = false,
    }) {
      return Expanded(
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          onTap: () {
            Navigator.pushNamed(context, route);
          },
          child: Semantics(
            label: 'Eco-friendly home navigation',
            button: true,
            child: AnimatedScale(
              scale: _iconScale,
              duration: Duration(milliseconds: 120),
              curve: Curves.easeInOut,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveHelper.getAdaptiveGap(context) * 0.5,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: active ? AppColors.white : AppColors.white.withOpacity(0.7),
                      size: ResponsiveHelper.getAdaptiveIconSize(context) * 0.8,
                    ),
                    SizedBox(height: ResponsiveHelper.getAdaptiveGap(context) * 0.25),
                    Text(
                      label,
                      style: AppTheme.caption.copyWith(
                        color: active ? AppColors.white : AppColors.white.withOpacity(0.7),
                        fontSize: ResponsiveHelper.getBodyFontSize(context) * 0.7,
                        fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: ResponsiveHelper.getBottomNavHeight(context),
      decoration: BoxDecoration(
        color: AppColors.footerBackground,
        border: Border(
          top: BorderSide(
            color: AppColors.secondary.withOpacity(0.18),
            width: ResponsiveHelper.getDividerThickness(context),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: ResponsiveHelper.getAdaptiveElevation(context) * 2,
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
