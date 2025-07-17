import 'package:flutter/material.dart';
import 'dart:io';

class LocalImageWidget extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  const LocalImageWidget(this.path, {this.fit = BoxFit.cover, this.width, this.height, super.key});
  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(path),
      fit: fit,
      width: width,
      height: height,
    );
  }
} 