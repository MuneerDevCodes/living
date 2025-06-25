import 'package:flutter/material.dart';
import 'package:living/style/theme.dart';

class Loader extends StatelessWidget {
  const Loader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgColor.withAlpha((0.7 * 255).toInt()),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(blackberry),
          strokeWidth: 3.5,
        ),
      ),
    );
  }
}
