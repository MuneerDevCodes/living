import 'package:flutter/material.dart';

class ResponsiveHelper {
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // Flexible padding that adapts to screen size
  static EdgeInsets getAdaptivePadding(BuildContext context) {
    final width = getScreenWidth(context);
    final height = getScreenHeight(context);
    
    // Use the smaller dimension to determine padding
    final baseSize = width < height ? width : height;
    final padding = (baseSize * 0.04).clamp(8.0, 24.0);
    
    return EdgeInsets.all(padding);
  }

  // Flexible horizontal padding
  static EdgeInsets getHorizontalPadding(BuildContext context) {
    final width = getScreenWidth(context);
    final padding = (width * 0.05).clamp(12.0, 32.0);
    
    return EdgeInsets.symmetric(horizontal: padding);
  }

  // Flexible vertical padding
  static EdgeInsets getVerticalPadding(BuildContext context) {
    final height = getScreenHeight(context);
    final padding = (height * 0.02).clamp(8.0, 24.0);
    
    return EdgeInsets.symmetric(vertical: padding);
  }

  // Adaptive spacing
  static double getAdaptiveSpacing(BuildContext context) {
    final width = getScreenWidth(context);
    final height = getScreenHeight(context);
    final baseSize = width < height ? width : height;
    
    return (baseSize * 0.02).clamp(8.0, 20.0);
  }

  // Adaptive font size
  static double getAdaptiveFontSize(BuildContext context, {double baseSize = 16.0}) {
    final width = getScreenWidth(context);
    final height = getScreenHeight(context);
    final baseDimension = width < height ? width : height;
    
    return (baseDimension * baseSize / 400).clamp(baseSize * 0.8, baseSize * 1.4);
  }

  // Flexible container constraints
  static BoxConstraints getFlexibleConstraints(BuildContext context) {
    final width = getScreenWidth(context);
    final height = getScreenHeight(context);
    
    // Use 90% of screen width, but cap at 600px for larger screens
    final maxWidth = (width * 0.9).clamp(300.0, 600.0);
    
    return BoxConstraints(
      maxWidth: maxWidth,
      minHeight: height * 0.3,
    );
  }

  // Adaptive card padding
  static EdgeInsets getCardPadding(BuildContext context) {
    final width = getScreenWidth(context);
    final padding = (width * 0.04).clamp(16.0, 32.0);
    
    return EdgeInsets.all(padding);
  }

  // Adaptive border radius
  static double getAdaptiveBorderRadius(BuildContext context) {
    final width = getScreenWidth(context);
    return (width * 0.02).clamp(8.0, 20.0);
  }

  // Flexible grid cross axis count
  static int getAdaptiveCrossAxisCount(BuildContext context) {
    final width = getScreenWidth(context);
    
    if (width < 400) return 1;
    if (width < 600) return 2;
    if (width < 800) return 3;
    return 4;
  }

  // Adaptive image size
  static double getAdaptiveImageSize(BuildContext context) {
    final width = getScreenWidth(context);
    return (width * 0.15).clamp(40.0, 80.0);
  }

  // Adaptive icon size
  static double getAdaptiveIconSize(BuildContext context) {
    final width = getScreenWidth(context);
    return (width * 0.06).clamp(16.0, 32.0);
  }

  // Flexible aspect ratio for cards
  static double getAdaptiveAspectRatio(BuildContext context) {
    final width = getScreenWidth(context);
    
    if (width < 400) return 3.0;
    if (width < 600) return 2.5;
    return 2.0;
  }
} 