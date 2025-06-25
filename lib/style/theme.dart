// lib/models/theme.dart
import 'package:flutter/material.dart';

const Color blackberry = Color(0xFF48182F);
const Color moonstone = Color(0xFFD4CBC4);
const Color bgColor = Color(0xFFF5F5F5); // background color

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
