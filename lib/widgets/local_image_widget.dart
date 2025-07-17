// local_image_widget.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Export the correct implementation based on platform
// local_image_widget_stub.dart will be used for web, local_image_widget_io.dart for others
export 'local_image_widget_stub.dart'
    if (dart.library.io) 'local_image_widget_io.dart'; 