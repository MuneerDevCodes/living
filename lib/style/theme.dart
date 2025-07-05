// lib/style/theme.dart
import 'package:flutter/material.dart';

// Primary Colors
const Color blackberry = Color(0xFF48182F);
const Color moonstone = Color(0xFFD4CBC4);
const Color bgColor = Color(0xFFF5F5F5);

// Extended Color Palette
class AppColors {
  // Primary Colors
  static const Color primary = blackberry;
  static const Color secondary = moonstone;
  static const Color background = bgColor;
  static const Color white = Colors.white;
  
  // Semantic Colors
  static const Color primaryText = Color(0xFF2C2C2C);
  static const Color secondaryText = Color(0xFF666666);
  static const Color mutedText = Color(0xFF999999);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Background Colors
  static const Color cardBackground = Colors.white;
  static const Color surfaceBackground = Color(0xFFFAFAFA);
  static const Color headerBackground = blackberry;
  static const Color footerBackground = blackberry;
  
  // Border Colors
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderMedium = Color(0xFFCCCCCC);
  static const Color borderDark = Color(0xFF999999);
  
  // Interactive Colors
  static const Color buttonPrimary = blackberry;
  static const Color buttonSecondary = moonstone;
  static const Color buttonDisabled = Color(0xFFCCCCCC);
  static const Color linkColor = Color(0xFF1976D2);
  
  // Shadow Colors
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);
  static const Color shadowDark = Color(0x4D000000);
  
  // Overlay Colors
  static const Color overlayLight = Color(0x80000000);
  static const Color overlayMedium = Color(0xB3000000);
  static const Color overlayDark = Color(0xE6000000);
  
  // Gradient Colors
  static const Color gradientStart = Color(0xFF48182F);
  static const Color gradientEnd = Color(0xFF6B2A4A);
  
  // Material Theme Colors
  static const MaterialColor primarySwatch = MaterialColor(
    0xFF48182F,
    <int, Color>{
      50: Color(0xFFF3E5F0),
      100: Color(0xFFE1BED9),
      200: Color(0xFFCD93C0),
      300: Color(0xFFB968A7),
      400: Color(0xFFA94D94),
      500: Color(0xFF48182F), // primary
      600: Color(0xFF8A2A7A),
      700: Color(0xFF7A2368),
      800: Color(0xFF6A1C56),
      900: Color(0xFF5A153F),
    },
  );
}

// Theme Data
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: AppColors.primarySwatch,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.cardBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceBackground,
        background: AppColors.background,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: AppColors.primaryText,
        onSurface: AppColors.primaryText,
        onBackground: AppColors.primaryText,
        onError: Colors.white,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.primaryText),
        displayMedium: TextStyle(color: AppColors.primaryText),
        displaySmall: TextStyle(color: AppColors.primaryText),
        headlineLarge: TextStyle(color: AppColors.primaryText),
        headlineMedium: TextStyle(color: AppColors.primaryText),
        headlineSmall: TextStyle(color: AppColors.primaryText),
        titleLarge: TextStyle(color: AppColors.primaryText),
        titleMedium: TextStyle(color: AppColors.primaryText),
        titleSmall: TextStyle(color: AppColors.primaryText),
        bodyLarge: TextStyle(color: AppColors.primaryText),
        bodyMedium: TextStyle(color: AppColors.primaryText),
        bodySmall: TextStyle(color: AppColors.secondaryText),
        labelLarge: TextStyle(color: AppColors.primaryText),
        labelMedium: TextStyle(color: AppColors.primaryText),
        labelSmall: TextStyle(color: AppColors.secondaryText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.buttonDisabled,
          disabledForegroundColor: AppColors.mutedText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.buttonPrimary,
          side: const BorderSide(color: AppColors.buttonPrimary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.linkColor,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.cardBackground,
        elevation: 2,
        shadowColor: AppColors.shadowLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.headerBackground,
        foregroundColor: AppColors.secondary,
        elevation: 0,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.cardBackground,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.footerBackground,
        selectedItemColor: Colors.white,
        unselectedItemColor: AppColors.secondary,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child; // No scrollbar
  }
}
