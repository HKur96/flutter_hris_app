import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final GlobalKey<NavigatorState> gNavigatorKey = GlobalKey<NavigatorState>();

/// Menyetel apakah screen akan berorientasi Portrait atau Landscape.
void gSetDeviceOrientations({bool isLandscape = false}) {
  SystemChrome.setPreferredOrientations(
    isLandscape
        ? [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      // DeviceOrientation.portraitUp,
      // DeviceOrientation.portraitDown,
    ]
        : [DeviceOrientation.portraitUp],
  );
}