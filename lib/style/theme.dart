// lib/style/theme.dart
import 'package:flutter/material.dart';

// Primary Colors - Green-focused sustainable theme
const Color primaryGreen = Color(0xFF2E7D32); // Deep green
const Color secondaryGreen = Color(0xFF4CAF50); // Medium green
const Color lightGreen = Color(0xFF81C784); // Light green
const Color bgColor = Color(0xFFF8FBF8); // Very light green tint

// Extended Color Palette
class AppColors {
  // Primary Colors
  static const Color primary = primaryGreen;
  static const Color secondary = secondaryGreen;
  static const Color tertiary = lightGreen;
  static const Color background = bgColor;
  static const Color white = Colors.white;
  
  // Semantic Colors
  static const Color primaryText = Color(0xFF1B5E20); // Dark green
  static const Color secondaryText = Color(0xFF4A6741); // Medium green-gray
  static const Color mutedText = Color(0xFF6B8E6B); // Light green-gray
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50); // Green
  static const Color warning = Color(0xFFFF9800); // Orange
  static const Color error = Color(0xFFF44336); // Red
  static const Color info = Color(0xFF2196F3); // Blue
  
  // Background Colors
  static const Color cardBackground = Colors.white;
  static const Color surfaceBackground = Color(0xFFF1F8E9); // Very light green
  static const Color headerBackground = primaryGreen;
  static const Color footerBackground = primaryGreen;
  
  // Border Colors
  static const Color borderLight = Color(0xFFE8F5E8); // Very light green
  static const Color borderMedium = Color(0xFFC8E6C9); // Light green
  static const Color borderDark = Color(0xFFA5D6A7); // Medium light green
  
  // Interactive Colors
  static const Color buttonPrimary = primaryGreen;
  static const Color buttonSecondary = secondaryGreen;
  static const Color buttonDisabled = Color(0xFFCCCCCC);
  static const Color linkColor = Color(0xFF1976D2);
  
  // Shadow Colors
  static const Color shadowLight = Color(0x1A2E7D32); // Green shadow
  static const Color shadowMedium = Color(0x332E7D32);
  static const Color shadowDark = Color(0x4D2E7D32);
  
  // Overlay Colors
  static const Color overlayLight = Color(0x80000000);
  static const Color overlayMedium = Color(0xB3000000);
  static const Color overlayDark = Color(0xE6000000);
  
  // Gradient Colors
  static const Color gradientStart = primaryGreen;
  static const Color gradientEnd = Color(0xFF1B5E20); // Darker green
  
  // Material Theme Colors
  static const MaterialColor primarySwatch = MaterialColor(
    0xFF2E7D32,
    <int, Color>{
      50: Color(0xFFE8F5E8),
      100: Color(0xFFC8E6C9),
      200: Color(0xFFA5D6A7),
      300: Color(0xFF81C784),
      400: Color(0xFF66BB6A),
      500: Color(0xFF4CAF50), // primary
      600: Color(0xFF43A047),
      700: Color(0xFF388E3C),
      800: Color(0xFF2E7D32), // main primary
      900: Color(0xFF1B5E20),
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
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: AppColors.primaryText,
        onSurface: AppColors.primaryText,
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
          elevation: 2,
          shadowColor: AppColors.shadowLight,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.headerBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: AppColors.shadowLight,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.cardBackground,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.footerBackground,
        selectedItemColor: Colors.white,
        unselectedItemColor: AppColors.tertiary,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderMedium),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        filled: true,
        fillColor: AppColors.surfaceBackground,
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
