import 'package:flutter/material.dart';
import 'package:living/style/theme.dart';
import 'package:living/style/responsive_helper.dart';

/// A responsive loader widget with theme-driven background and progress color.
class Loader extends StatelessWidget {
  const Loader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background.withOpacity(0.7),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          strokeWidth: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2,
        ),
      ),
    );
  }
}
