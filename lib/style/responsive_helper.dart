import 'package:flutter/material.dart';

class ResponsiveHelper {
  // Screen dimensions
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // Device type detection
  static bool isMobile(BuildContext context) {
    return getScreenWidth(context) < 600;
  }

  static bool isTablet(BuildContext context) {
    final width = getScreenWidth(context);
    return width >= 600 && width < 1024;
  }

  static bool isDesktop(BuildContext context) {
    return getScreenWidth(context) >= 1024;
  }

  static bool isLargeScreen(BuildContext context) {
    return getScreenWidth(context) >= 1440;
  }

  // Responsive breakpoints
  static double getBreakpoint(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 600) return width; // Mobile
    if (width < 1024) return 600; // Tablet
    if (width < 1440) return 1024; // Desktop
    return 1440; // Large screen
  }

  // Adaptive padding system
  static EdgeInsets getAdaptivePadding(BuildContext context) {
    final width = getScreenWidth(context);
    
    if (isMobile(context)) {
      return EdgeInsets.all(width * 0.04);
    } else if (isTablet(context)) {
      return EdgeInsets.all(24.0);
    } else if (isDesktop(context)) {
      return EdgeInsets.all(32.0);
    } else {
      return EdgeInsets.all(40.0);
    }
  }

  static EdgeInsets getHorizontalPadding(BuildContext context) {
    final width = getScreenWidth(context);
    
    if (isMobile(context)) {
      return EdgeInsets.symmetric(horizontal: width * 0.04);
    } else if (isTablet(context)) {
      return EdgeInsets.symmetric(horizontal: 32.0);
    } else if (isDesktop(context)) {
      return EdgeInsets.symmetric(horizontal: 48.0);
    } else {
      return EdgeInsets.symmetric(horizontal: 64.0);
    }
  }

  static EdgeInsets getVerticalPadding(BuildContext context) {
    final height = getScreenHeight(context);
    
    if (isMobile(context)) {
      return EdgeInsets.symmetric(vertical: height * 0.02);
    } else if (isTablet(context)) {
      return EdgeInsets.symmetric(vertical: 16.0);
    } else {
      return EdgeInsets.symmetric(vertical: 24.0);
    }
  }

  // Adaptive spacing
  static double getAdaptiveSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 16.0;
    } else if (isTablet(context)) {
      return 20.0;
    } else {
      return 24.0;
    }
  }

  // Adaptive font sizes
  static double getAdaptiveFontSize(BuildContext context, {double baseSize = 16.0}) {
    if (isMobile(context)) {
      return baseSize;
    } else if (isTablet(context)) {
      return baseSize * 1.1;
    } else if (isDesktop(context)) {
      return baseSize * 1.2;
    } else {
      return baseSize * 1.3;
    }
  }

  static double getTitleFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 24.0;
    } else if (isTablet(context)) {
      return 28.0;
    } else if (isDesktop(context)) {
      return 32.0;
    } else {
      return 36.0;
    }
  }

  static double getSubtitleFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 18.0;
    } else if (isTablet(context)) {
      return 20.0;
    } else if (isDesktop(context)) {
      return 22.0;
    } else {
      return 24.0;
    }
  }

  static double getBodyFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 14.0;
    } else if (isTablet(context)) {
      return 16.0;
    } else {
      return 18.0;
    }
  }

  // Flexible container constraints
  static BoxConstraints getFlexibleConstraints(BuildContext context) {
    final width = getScreenWidth(context);
    
    if (isMobile(context)) {
      return BoxConstraints(
        maxWidth: width * 0.95,
        minHeight: 100.0,
      );
    } else if (isTablet(context)) {
      return BoxConstraints(
        maxWidth: width * 0.9,
        minHeight: 120.0,
      );
    } else if (isDesktop(context)) {
      return BoxConstraints(
        maxWidth: width * 0.8,
        minHeight: 150.0,
      );
    } else {
      return BoxConstraints(
        maxWidth: 1200.0,
        minHeight: 180.0,
      );
    }
  }

  // Adaptive card padding
  static EdgeInsets getCardPadding(BuildContext context) {
    if (isMobile(context)) {
      return EdgeInsets.all(16.0);
    } else if (isTablet(context)) {
      return EdgeInsets.all(20.0);
    } else {
      return EdgeInsets.all(24.0);
    }
  }

  // Adaptive border radius
  static double getAdaptiveBorderRadius(BuildContext context) {
    if (isMobile(context)) {
      return 12.0;
    } else if (isTablet(context)) {
      return 16.0;
    } else {
      return 20.0;
    }
  }

  // Responsive grid system
  static int getAdaptiveCrossAxisCount(BuildContext context) {
    if (isMobile(context)) {
      return 1;
    } else if (isTablet(context)) {
      return 2;
    } else if (isDesktop(context)) {
      return 3;
    } else {
      return 4;
    }
  }

  static double getGridChildAspectRatio(BuildContext context) {
    if (isMobile(context)) {
      return 1.2;
    } else if (isTablet(context)) {
      return 1.0;
    } else {
      return 0.8;
    }
  }

  // Adaptive image sizes
  static double getAdaptiveImageSize(BuildContext context) {
    if (isMobile(context)) {
      return 60.0;
    } else if (isTablet(context)) {
      return 80.0;
    } else {
      return 100.0;
    }
  }

  static double getAdaptiveIconSize(BuildContext context) {
    if (isMobile(context)) {
      return 20.0;
    } else if (isTablet(context)) {
      return 24.0;
    } else {
      return 28.0;
    }
  }

  // Flexible aspect ratio for cards
  static double getAdaptiveAspectRatio(BuildContext context) {
    if (isMobile(context)) {
      return 2.5;
    } else if (isTablet(context)) {
      return 2.0;
    } else {
      return 1.5;
    }
  }

  // Responsive header/footer height
  static double getHeaderFooterHeight(BuildContext context) {
    if (isMobile(context)) {
      return 60.0;
    } else if (isTablet(context)) {
      return 70.0;
    } else {
      return 80.0;
    }
  }

  // Responsive button sizes
  static double getButtonHeight(BuildContext context) {
    if (isMobile(context)) {
      return 48.0;
    } else if (isTablet(context)) {
      return 52.0;
    } else {
      return 56.0;
    }
  }

  static double getButtonFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 14.0;
    } else if (isTablet(context)) {
      return 16.0;
    } else {
      return 18.0;
    }
  }

  // Responsive input field sizes
  static double getInputFieldHeight(BuildContext context) {
    if (isMobile(context)) {
      return 48.0;
    } else if (isTablet(context)) {
      return 52.0;
    } else {
      return 56.0;
    }
  }

  // Responsive list tile sizes
  static double getListTileHeight(BuildContext context) {
    if (isMobile(context)) {
      return 72.0;
    } else if (isTablet(context)) {
      return 80.0;
    } else {
      return 88.0;
    }
  }

  // Responsive drawer width
  static double getDrawerWidth(BuildContext context) {
    if (isMobile(context)) {
      return getScreenWidth(context) * 0.8;
    } else if (isTablet(context)) {
      return 300.0;
    } else {
      return 350.0;
    }
  }

  // Responsive bottom navigation height
  static double getBottomNavHeight(BuildContext context) {
    if (isMobile(context)) {
      return 60.0;
    } else {
      return 70.0;
    }
  }

  // Responsive floating action button size
  static double getFABSize(BuildContext context) {
    if (isMobile(context)) {
      return 56.0;
    } else if (isTablet(context)) {
      return 64.0;
    } else {
      return 72.0;
    }
  }

  // Responsive app bar height
  static double getAppBarHeight(BuildContext context) {
    if (isMobile(context)) {
      return 56.0;
    } else if (isTablet(context)) {
      return 64.0;
    } else {
      return 72.0;
    }
  }

  // Responsive bottom sheet height
  static double getBottomSheetHeight(BuildContext context) {
    final height = getScreenHeight(context);
    if (isMobile(context)) {
      return height * 0.6;
    } else if (isTablet(context)) {
      return height * 0.5;
    } else {
      return height * 0.4;
    }
  }

  // Responsive dialog size
  static double getDialogWidth(BuildContext context) {
    final width = getScreenWidth(context);
    if (isMobile(context)) {
      return width * 0.9;
    } else if (isTablet(context)) {
      return width * 0.7;
    } else {
      return 500.0;
    }
  }

  // Responsive chip size
  static double getChipHeight(BuildContext context) {
    if (isMobile(context)) {
      return 32.0;
    } else if (isTablet(context)) {
      return 36.0;
    } else {
      return 40.0;
    }
  }

  // Responsive divider thickness
  static double getDividerThickness(BuildContext context) {
    if (isMobile(context)) {
      return 1.0;
    } else {
      return 2.0;
    }
  }

  // Responsive elevation
  static double getAdaptiveElevation(BuildContext context) {
    if (isMobile(context)) {
      return 2.0;
    } else if (isTablet(context)) {
      return 3.0;
    } else {
      return 4.0;
    }
  }

  // Responsive margin
  static EdgeInsets getAdaptiveMargin(BuildContext context) {
    if (isMobile(context)) {
      return EdgeInsets.all(8.0);
    } else if (isTablet(context)) {
      return EdgeInsets.all(12.0);
    } else {
      return EdgeInsets.all(16.0);
    }
  }

  // Responsive gap
  static double getAdaptiveGap(BuildContext context) {
    if (isMobile(context)) {
      return 8.0;
    } else if (isTablet(context)) {
      return 12.0;
    } else {
      return 16.0;
    }
  }

  // Responsive section spacing
  static double getSectionSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 24.0;
    } else if (isTablet(context)) {
      return 32.0;
    } else {
      return 40.0;
    }
  }

  // Responsive content width
  static double getContentWidth(BuildContext context) {
    final width = getScreenWidth(context);
    if (isMobile(context)) {
      return width * 0.95;
    } else if (isTablet(context)) {
      return width * 0.9;
    } else if (isDesktop(context)) {
      return width * 0.8;
    } else {
      return 1200.0;
    }
  }

  // Responsive sidebar width
  static double getSidebarWidth(BuildContext context) {
    if (isMobile(context)) {
      return 0.0; // No sidebar on mobile
    } else if (isTablet(context)) {
      return 200.0;
    } else {
      return 250.0;
    }
  }

  // Responsive main content area
  static double getMainContentWidth(BuildContext context) {
    final width = getScreenWidth(context);
    final sidebarWidth = getSidebarWidth(context);
    
    if (isMobile(context)) {
      return width;
    } else {
      return width - sidebarWidth;
    }
  }
} 