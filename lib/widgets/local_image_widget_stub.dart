import 'package:flutter/material.dart';

class LocalImageWidget extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  const LocalImageWidget(this.path, {this.fit = BoxFit.cover, this.width, this.height, super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      width: width,
      height: height,
      child: const Center(
        child: Text(
          'Local images not supported on Web',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
} 