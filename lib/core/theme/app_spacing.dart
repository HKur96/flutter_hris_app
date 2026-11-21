import 'package:flutter/material.dart';

/// Skala Spacing berbasis grid 4pt resmi KaryaHR Mobile.
class AppSpacing {
  AppSpacing._();

  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0; // Standar padding horizontal layar mobile
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;

  // EdgeInsets helper konstan
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: space16,
    vertical: space20,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(space12);
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: space12,
    vertical: space12,
  );

  static const EdgeInsets dialogPadding = EdgeInsets.all(space20);
  static const EdgeInsets badgePadding = EdgeInsets.symmetric(
    horizontal: space8,
    vertical: space4,
  );
}
