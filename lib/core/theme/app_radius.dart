import 'package:flutter/material.dart';

/// Token Border Radius resmi KaryaHR Mobile (Strict Anti AI-Slop).
/// Menghindari rounded pill 9999px ekstrem pada container konten.
class AppRadius {
  AppRadius._();

  static const double small = 4.0; // Badge status, chip filter, checkbox
  static const double medium = 8.0; // Default: input field, button, container card
  static const double large = 12.0; // Modal bottom sheet, confirmation dialog
  static const double xl = 16.0; // Showcase card & preview frames

  // BorderRadius helper
  static const BorderRadius roundedSmall = BorderRadius.all(Radius.circular(small));
  static const BorderRadius roundedMedium = BorderRadius.all(Radius.circular(medium));
  static const BorderRadius roundedLarge = BorderRadius.all(Radius.circular(large));
  static const BorderRadius roundedTopLarge = BorderRadius.vertical(top: Radius.circular(large));
}

/// Alias AppShapes untuk kompatibilitas
class AppShapes {
  AppShapes._();

  static const double radiusSm = AppRadius.small;
  static const double radiusMd = AppRadius.medium;
  static const double radiusLg = AppRadius.large;

  static const BorderRadius roundedSm = AppRadius.roundedSmall;
  static const BorderRadius roundedMd = AppRadius.roundedMedium;
  static const BorderRadius roundedLg = AppRadius.roundedLarge;
}
