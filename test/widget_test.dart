// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:living/screens/home_page.dart';
import 'package:living/style/responsive_helper.dart';

void main() {
  group('HomePage Responsive Tests', () {
    testWidgets('HomePage renders correctly on mobile', (WidgetTester tester) async {
      // Set mobile screen size
      tester.binding.window.physicalSizeTestValue = const Size(375, 812);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();
      
      // Verify mobile-specific elements are present
      expect(find.text('Welcome to'), findsOneWidget);
      expect(find.text('Sustainable Living'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Learn More'), findsOneWidget);
      expect(find.text('What We Offer'), findsOneWidget);
      expect(find.text('Explore Features'), findsOneWidget);
    });

    testWidgets('HomePage renders correctly on tablet', (WidgetTester tester) async {
      // Set tablet screen size
      tester.binding.window.physicalSizeTestValue = const Size(768, 1024);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();
      
      // Verify tablet-specific elements are present
      expect(find.text('Welcome to'), findsOneWidget);
      expect(find.text('Sustainable Living'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Learn More'), findsOneWidget);
    });

    testWidgets('HomePage renders correctly on desktop', (WidgetTester tester) async {
      // Set desktop screen size
      tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();
      
      // Verify desktop-specific elements are present
      expect(find.text('Welcome to'), findsOneWidget);
      expect(find.text('Sustainable Living'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Learn More'), findsOneWidget);
    });

    testWidgets('ResponsiveHelper methods work correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      
      final context = tester.element(find.byType(HomePage));
      
      // Test mobile detection
      tester.binding.window.physicalSizeTestValue = const Size(375, 812);
      expect(ResponsiveHelper.isMobile(context), isTrue);
      expect(ResponsiveHelper.isTablet(context), isFalse);
      expect(ResponsiveHelper.isDesktop(context), isFalse);
      
      // Test tablet detection
      tester.binding.window.physicalSizeTestValue = const Size(768, 1024);
      expect(ResponsiveHelper.isMobile(context), isFalse);
      expect(ResponsiveHelper.isTablet(context), isTrue);
      expect(ResponsiveHelper.isDesktop(context), isFalse);
      
      // Test desktop detection
      tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);
      expect(ResponsiveHelper.isMobile(context), isFalse);
      expect(ResponsiveHelper.isTablet(context), isFalse);
      expect(ResponsiveHelper.isDesktop(context), isTrue);
    });
  });
}
