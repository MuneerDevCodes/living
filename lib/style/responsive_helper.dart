import 'package:flutter/material.dart';

/// ResponsiveHelper provides utilities for responsive layouts, sizing, spacing, and device detection.
/// Enhanced to prevent overflow issues on all screen sizes.
class ResponsiveHelper {
  // Screen dimensions with safe area consideration
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static double getAvailableWidth(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return getScreenWidth(context) - padding.left - padding.right;
  }

  static double getAvailableHeight(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return getScreenHeight(context) - padding.top - padding.bottom;
  }

  // Enhanced breakpoints for better mobile coverage
  static bool isSmallMobile(BuildContext context) {
    return getScreenWidth(context) < 360; // Very small phones
  }

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

  // Overflow prevention helpers
  static Widget preventOverflow(Widget child, {EdgeInsets? padding}) {
    return SingleChildScrollView(
      padding: padding,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 0),
        child: IntrinsicHeight(child: child),
      ),
    );
  }

  static Widget flexibleContainer(Widget child, {double? maxWidth}) {
    return Flexible(
      child: Container(
        constraints: maxWidth != null 
          ? BoxConstraints(maxWidth: maxWidth)
          : null,
        child: child,
      ),
    );
  }

  static Widget expandedContainer(Widget child) {
    return Expanded(child: child);
  }

  // Enhanced adaptive padding system
  static EdgeInsets getAdaptivePadding(BuildContext context) {
    final width = getScreenWidth(context);
    
    if (isSmallMobile(context)) {
      return EdgeInsets.all(width * 0.03); // Very small padding for tiny screens
    } else if (isMobile(context)) {
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
    
    if (isSmallMobile(context)) {
      return EdgeInsets.symmetric(horizontal: width * 0.015); // Very small horizontal padding
    } else if (isMobile(context)) {
      return EdgeInsets.symmetric(horizontal: width * 0.02);
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
    
    if (isSmallMobile(context)) {
      return EdgeInsets.symmetric(vertical: height * 0.015);
    } else if (isMobile(context)) {
      return EdgeInsets.symmetric(vertical: height * 0.02);
    } else if (isTablet(context)) {
      return EdgeInsets.symmetric(vertical: 16.0);
    } else {
      return EdgeInsets.symmetric(vertical: 24.0);
    }
  }

  // Enhanced adaptive spacing
  static double getAdaptiveSpacing(BuildContext context) {
    if (isSmallMobile(context)) {
      return 12.0; // Smaller spacing for very small screens
    } else if (isMobile(context)) {
      return 16.0;
    } else if (isTablet(context)) {
      return 20.0;
    } else {
      return 24.0;
    }
  }

  // Enhanced adaptive font sizes with overflow prevention
  static double getAdaptiveFontSize(BuildContext context, {double baseSize = 16.0}) {
    if (isSmallMobile(context)) {
      return baseSize * 0.9; // Smaller fonts for very small screens
    } else if (isMobile(context)) {
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
    if (isSmallMobile(context)) {
      return 20.0; // Smaller title for very small screens
    } else if (isMobile(context)) {
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
    if (isSmallMobile(context)) {
      return 16.0;
    } else if (isMobile(context)) {
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
    if (isSmallMobile(context)) {
      return 12.0; // Smaller body text for very small screens
    } else if (isMobile(context)) {
      return 14.0;
    } else if (isTablet(context)) {
      return 16.0;
    } else {
      return 18.0;
    }
  }

  // Enhanced flexible container constraints
  static BoxConstraints getFlexibleConstraints(BuildContext context) {
    final width = getAvailableWidth(context);
    
    if (isSmallMobile(context)) {
      return BoxConstraints(
        maxWidth: width * 0.98, // Use almost full width
        minHeight: 80.0, // Smaller min height
      );
    } else if (isMobile(context)) {
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

  // Enhanced adaptive card padding
  static EdgeInsets getCardPadding(BuildContext context) {
    if (isSmallMobile(context)) {
      return EdgeInsets.all(12.0); // Smaller padding for very small screens
    } else if (isMobile(context)) {
      return EdgeInsets.all(16.0);
    } else if (isTablet(context)) {
      return EdgeInsets.all(20.0);
    } else {
      return EdgeInsets.all(24.0);
    }
  }

  // Enhanced adaptive border radius
  static double getAdaptiveBorderRadius(BuildContext context) {
    if (isSmallMobile(context)) {
      return 8.0; // Smaller radius for very small screens
    } else if (isMobile(context)) {
      return 12.0;
    } else if (isTablet(context)) {
      return 16.0;
    } else {
      return 20.0;
    }
  }

  // Enhanced responsive grid system
  static int getAdaptiveCrossAxisCount(BuildContext context) {
    if (isSmallMobile(context)) {
      return 1; // Single column for very small screens
    } else if (isMobile(context)) {
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
    if (isSmallMobile(context)) {
      return 1.5; // Taller cards for very small screens
    } else if (isMobile(context)) {
      return 1.2;
    } else if (isTablet(context)) {
      return 1.0;
    } else {
      return 0.8;
    }
  }

  // Enhanced adaptive image sizes
  static double getAdaptiveImageSize(BuildContext context) {
    if (isSmallMobile(context)) {
      return 40.0; // Smaller images for very small screens
    } else if (isMobile(context)) {
      return 60.0;
    } else if (isTablet(context)) {
      return 80.0;
    } else {
      return 100.0;
    }
  }

  static double getAdaptiveIconSize(BuildContext context) {
    if (isSmallMobile(context)) {
      return 16.0; // Smaller icons for very small screens
    } else if (isMobile(context)) {
      return 18.0;
    } else if (isTablet(context)) {
      return 24.0;
    } else {
      return 28.0;
    }
  }

  static double getCompactIconSize(BuildContext context) {
    if (isSmallMobile(context)) {
      return 14.0; // Even smaller for very small screens
    } else if (isMobile(context)) {
      return 16.0;
    } else if (isTablet(context)) {
      return 20.0;
    } else {
      return 24.0;
    }
  }

  // Enhanced flexible aspect ratio for cards
  static double getAdaptiveAspectRatio(BuildContext context) {
    if (isSmallMobile(context)) {
      return 3.0; // Very tall cards for very small screens
    } else if (isMobile(context)) {
      return 2.5;
    } else if (isTablet(context)) {
      return 2.0;
    } else {
      return 1.5;
    }
  }

  /// Returns the responsive header/footer height for the current device.
  static double getHeaderFooterHeight(BuildContext context) {
    if (isSmallMobile(context)) {
      return 50.0; // Smaller header for very small screens
    } else if (isMobile(context)) {
      return 60.0;
    } else if (isTablet(context)) {
      return 70.0;
    } else {
      return 80.0;
    }
  }

  // Enhanced responsive button sizes
  static double getButtonHeight(BuildContext context) {
    if (isSmallMobile(context)) {
      return 40.0; // Smaller buttons for very small screens
    } else if (isMobile(context)) {
      return 44.0;
    } else if (isTablet(context)) {
      return 52.0;
    } else {
      return 56.0;
    }
  }

  static double getButtonFontSize(BuildContext context) {
    if (isSmallMobile(context)) {
      return 12.0; // Smaller button text for very small screens
    } else if (isMobile(context)) {
      return 14.0;
    } else if (isTablet(context)) {
      return 16.0;
    } else {
      return 18.0;
    }
  }

  // Enhanced responsive input field sizes
  static double getInputFieldHeight(BuildContext context) {
    if (isSmallMobile(context)) {
      return 44.0; // Smaller input fields for very small screens
    } else if (isMobile(context)) {
      return 48.0;
    } else if (isTablet(context)) {
      return 52.0;
    } else {
      return 56.0;
    }
  }

  // Enhanced responsive list tile sizes
  static double getListTileHeight(BuildContext context) {
    if (isSmallMobile(context)) {
      return 64.0; // Smaller list tiles for very small screens
    } else if (isMobile(context)) {
      return 72.0;
    } else if (isTablet(context)) {
      return 80.0;
    } else {
      return 88.0;
    }
  }

  // Enhanced responsive drawer width
  static double getDrawerWidth(BuildContext context) {
    if (isSmallMobile(context)) {
      return getScreenWidth(context) * 0.85; // Smaller drawer for very small screens
    } else if (isMobile(context)) {
      return getScreenWidth(context) * 0.8;
    } else if (isTablet(context)) {
      return 300.0;
    } else {
      return 350.0;
    }
  }

  // Enhanced responsive bottom navigation height
  static double getBottomNavHeight(BuildContext context) {
    if (isSmallMobile(context)) {
      return 50.0; // Smaller bottom nav for very small screens
    } else if (isMobile(context)) {
      return 60.0;
    } else {
      return 70.0;
    }
  }

  // Enhanced responsive floating action button size
  static double getFABSize(BuildContext context) {
    if (isSmallMobile(context)) {
      return 48.0; // Smaller FAB for very small screens
    } else if (isMobile(context)) {
      return 56.0;
    } else if (isTablet(context)) {
      return 64.0;
    } else {
      return 72.0;
    }
  }

  // Enhanced responsive app bar height
  static double getAppBarHeight(BuildContext context) {
    if (isSmallMobile(context)) {
      return 48.0; // Smaller app bar for very small screens
    } else if (isMobile(context)) {
      return 56.0;
    } else if (isTablet(context)) {
      return 64.0;
    } else {
      return 72.0;
    }
  }

  // Enhanced responsive bottom sheet height
  static double getBottomSheetHeight(BuildContext context) {
    final height = getAvailableHeight(context);
    if (isSmallMobile(context)) {
      return height * 0.7; // Larger percentage for very small screens
    } else if (isMobile(context)) {
      return height * 0.6;
    } else if (isTablet(context)) {
      return height * 0.5;
    } else {
      return height * 0.4;
    }
  }

  // Enhanced responsive dialog size
  static double getDialogWidth(BuildContext context) {
    final width = getAvailableWidth(context);
    if (isSmallMobile(context)) {
      return width * 0.95; // Almost full width for very small screens
    } else if (isMobile(context)) {
      return width * 0.9;
    } else if (isTablet(context)) {
      return width * 0.7;
    } else {
      return 500.0;
    }
  }

  // Enhanced responsive chip size
  static double getChipHeight(BuildContext context) {
    if (isSmallMobile(context)) {
      return 28.0; // Smaller chips for very small screens
    } else if (isMobile(context)) {
      return 32.0;
    } else if (isTablet(context)) {
      return 36.0;
    } else {
      return 40.0;
    }
  }

  // Enhanced responsive divider thickness
  static double getDividerThickness(BuildContext context) {
    if (isSmallMobile(context)) {
      return 0.5; // Thinner dividers for very small screens
    } else if (isMobile(context)) {
      return 1.0;
    } else {
      return 2.0;
    }
  }

  // Enhanced responsive elevation
  static double getAdaptiveElevation(BuildContext context) {
    if (isSmallMobile(context)) {
      return 1.0; // Lower elevation for very small screens
    } else if (isMobile(context)) {
      return 2.0;
    } else if (isTablet(context)) {
      return 3.0;
    } else {
      return 4.0;
    }
  }

  // Enhanced responsive margin
  static EdgeInsets getAdaptiveMargin(BuildContext context) {
    if (isSmallMobile(context)) {
      return EdgeInsets.all(6.0); // Smaller margins for very small screens
    } else if (isMobile(context)) {
      return EdgeInsets.all(8.0);
    } else if (isTablet(context)) {
      return EdgeInsets.all(12.0);
    } else {
      return EdgeInsets.all(16.0);
    }
  }

  // Enhanced responsive gap
  static double getAdaptiveGap(BuildContext context) {
    if (isSmallMobile(context)) {
      return 6.0; // Smaller gaps for very small screens
    } else if (isMobile(context)) {
      return 8.0;
    } else if (isTablet(context)) {
      return 12.0;
    } else {
      return 16.0;
    }
  }

  // Enhanced responsive section spacing
  static double getSectionSpacing(BuildContext context) {
    if (isSmallMobile(context)) {
      return 16.0; // Smaller section spacing for very small screens
    } else if (isMobile(context)) {
      return 24.0;
    } else if (isTablet(context)) {
      return 32.0;
    } else {
      return 40.0;
    }
  }

  // Enhanced responsive content width
  static double getContentWidth(BuildContext context) {
    final width = getAvailableWidth(context);
    if (isSmallMobile(context)) {
      return width * 0.98; // Almost full width for very small screens
    } else if (isMobile(context)) {
      return width * 0.95;
    } else if (isTablet(context)) {
      return width * 0.9;
    } else if (isDesktop(context)) {
      return width * 0.8;
    } else {
      return 1200.0;
    }
  }

  // Enhanced spacing for better visual hierarchy
  static double getLargeSpacing(BuildContext context) {
    if (isSmallMobile(context)) {
      return 20.0; // Smaller large spacing for very small screens
    } else if (isMobile(context)) {
      return 32.0;
    } else if (isTablet(context)) {
      return 40.0;
    } else {
      return 48.0;
    }
  }

  static double getMediumSpacing(BuildContext context) {
    if (isSmallMobile(context)) {
      return 16.0; // Smaller medium spacing for very small screens
    } else if (isMobile(context)) {
      return 24.0;
    } else if (isTablet(context)) {
      return 32.0;
    } else {
      return 40.0;
    }
  }

  static double getSmallSpacing(BuildContext context) {
    if (isSmallMobile(context)) {
      return 12.0; // Smaller small spacing for very small screens
    } else if (isMobile(context)) {
      return 16.0;
    } else if (isTablet(context)) {
      return 20.0;
    } else {
      return 24.0;
    }
  }

  // Enhanced icon sizes for better visual impact
  static double getLargeIconSize(BuildContext context) {
    if (isSmallMobile(context)) {
      return 24.0; // Smaller large icons for very small screens
    } else if (isMobile(context)) {
      return 32.0;
    } else if (isTablet(context)) {
      return 40.0;
    } else {
      return 48.0;
    }
  }

  static double getMediumIconSize(BuildContext context) {
    if (isSmallMobile(context)) {
      return 20.0; // Smaller medium icons for very small screens
    } else if (isMobile(context)) {
      return 24.0;
    } else if (isTablet(context)) {
      return 32.0;
    } else {
      return 40.0;
    }
  }

  // Enhanced button sizes
  static double getLargeButtonHeight(BuildContext context) {
    if (isSmallMobile(context)) {
      return 44.0; // Smaller large buttons for very small screens
    } else if (isMobile(context)) {
      return 56.0;
    } else if (isTablet(context)) {
      return 64.0;
    } else {
      return 72.0;
    }
  }

  static double getMediumButtonHeight(BuildContext context) {
    if (isSmallMobile(context)) {
      return 40.0; // Smaller medium buttons for very small screens
    } else if (isMobile(context)) {
      return 48.0;
    } else if (isTablet(context)) {
      return 56.0;
    } else {
      return 64.0;
    }
  }

  // Enhanced card padding
  static EdgeInsets getLargeCardPadding(BuildContext context) {
    if (isSmallMobile(context)) {
      return EdgeInsets.all(16.0); // Smaller large card padding for very small screens
    } else if (isMobile(context)) {
      return EdgeInsets.all(20.0);
    } else if (isTablet(context)) {
      return EdgeInsets.all(24.0);
    } else {
      return EdgeInsets.all(32.0);
    }
  }

  // Enhanced border radius
  static double getLargeBorderRadius(BuildContext context) {
    if (isSmallMobile(context)) {
      return 12.0; // Smaller large border radius for very small screens
    } else if (isMobile(context)) {
      return 16.0;
    } else if (isTablet(context)) {
      return 20.0;
    } else {
      return 24.0;
    }
  }

  // Enhanced responsive text scale factor
  static double getTextScaleFactor(BuildContext context) {
    if (isSmallMobile(context)) {
      return 0.9; // Smaller text scale for very small screens
    } else if (isMobile(context)) {
      return 1.0;
    } else if (isTablet(context)) {
      return 1.1;
    } else {
      return 1.2;
    }
  }

  // Enhanced responsive hero section height
  static double getHeroSectionHeight(BuildContext context) {
    if (isSmallMobile(context)) {
      return 200.0; // Smaller hero section for very small screens
    } else if (isMobile(context)) {
      return 300.0;
    } else if (isTablet(context)) {
      return 400.0;
    } else {
      return 500.0;
    }
  }

  // Enhanced responsive feature card aspect ratio
  static double getFeatureCardAspectRatio(BuildContext context) {
    if (isSmallMobile(context)) {
      return 2.2; // Very tall cards for very small screens
    } else if (isMobile(context)) {
      return 1.8;
    } else if (isTablet(context)) {
      return 1.5;
    } else {
      return 1.2;
    }
  }

  // Enhanced responsive gradient stops
  static List<double> getGradientStops(BuildContext context) {
    if (isSmallMobile(context)) {
      return [0.0, 1.0]; // Simple gradient for very small screens
    } else if (isMobile(context)) {
      return [0.0, 1.0];
    } else {
      return [0.0, 0.7, 1.0];
    }
  }

  // Enhanced responsive sidebar width
  static double getSidebarWidth(BuildContext context) {
    if (isSmallMobile(context)) {
      return 0.0; // No sidebar for very small screens
    } else if (isMobile(context)) {
      return 0.0; // No sidebar on mobile
    } else if (isTablet(context)) {
      return 200.0;
    } else {
      return 250.0;
    }
  }

  // Enhanced responsive main content area
  static double getMainContentWidth(BuildContext context) {
    final width = getAvailableWidth(context);
    final sidebarWidth = getSidebarWidth(context);
    
    if (isSmallMobile(context)) {
      return width; // Full width for very small screens
    } else if (isMobile(context)) {
      return width;
    } else {
      return width - sidebarWidth;
    }
  }

  // New methods for overflow prevention
  static Widget safeAreaWrapper(Widget child) {
    return SafeArea(child: child);
  }

  static Widget scrollableWrapper(Widget child, {EdgeInsets? padding}) {
    return SingleChildScrollView(
      padding: padding,
      child: child,
    );
  }

  static Widget flexibleWrapper(Widget child) {
    return Flexible(child: child);
  }

  static Widget expandedWrapper(Widget child) {
    return Expanded(child: child);
  }

  static Widget constrainedWrapper(Widget child, {double? maxWidth, double? maxHeight}) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? double.infinity,
        maxHeight: maxHeight ?? double.infinity,
      ),
      child: child,
    );
  }

  // Method to create responsive text that prevents overflow
  static Widget responsiveText(
    String text, {
    required BuildContext context,
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.ellipsis,
      textScaleFactor: getTextScaleFactor(context),
    );
  }

  // Method to create responsive buttons that prevent overflow
  static Widget responsiveButton({
    required BuildContext context,
    required VoidCallback? onPressed,
    required Widget child,
    ButtonStyle? style,
    bool isExpanded = false,
  }) {
    Widget button = ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: child,
    );

    if (isExpanded) {
      button = SizedBox(
        width: double.infinity,
        height: getButtonHeight(context),
        child: button,
      );
    }

    return button;
  }

  // Method to create responsive cards that prevent overflow
  static Widget responsiveCard({
    required BuildContext context,
    required Widget child,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    double? elevation,
    Color? color,
    ShapeBorder? shape,
  }) {
    return Card(
      margin: margin ?? getAdaptiveMargin(context),
      elevation: elevation ?? getAdaptiveElevation(context),
      color: color,
      shape: shape ?? RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(getAdaptiveBorderRadius(context)),
      ),
      child: Padding(
        padding: padding ?? getCardPadding(context),
        child: child,
      ),
    );
  }

  // Method to create responsive containers that prevent overflow
  static Widget responsiveContainer({
    required BuildContext context,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BoxConstraints? constraints,
    Decoration? decoration,
  }) {
    return Container(
      padding: padding ?? getAdaptivePadding(context),
      margin: margin ?? getAdaptiveMargin(context),
      constraints: constraints ?? getFlexibleConstraints(context),
      decoration: decoration,
      child: child,
    );
  }

} 