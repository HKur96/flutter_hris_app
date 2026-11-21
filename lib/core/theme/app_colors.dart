import 'package:flutter/material.dart';

/// Palet warna resmi KaryaHR Mobile sesuai Tahap 1 — Design Foundation.
/// Mengutamakan kontras WCAG AA, bebas gradien berlebih (Strict Anti AI-Slop).
class AppColors {
  AppColors._();

  // Primary Brand (Hijau Profesional)
  static const Color brand50 = Color(0xFFF0FDF4); // Tint background
  static const Color brand100 = Color(0xFFDCFCE7); // Tint badge
  static const Color brand200 = Color(0xFFBBF7D0); // Border tint
  static const Color brand500 = Color(0xFF22C55E);
  static const Color brand600 = Color(0xFF16A34A);
  static const Color brand700 = Color(0xFF15803D); // Primary Active Token
  static const Color brand800 = Color(0xFF166534); // Primary Dark / Pressed
  static const Color brand900 = Color(0xFF14532D);

  // Shortcut alias untuk kemudahan penggunaan
  static const Color primary = brand700;
  static const Color primaryDark = brand800;
  static const Color primaryLight = brand100;
  static const Color primaryTint = brand50;
  static const Color primaryBrand = brand700;
  static const Color onPrimary = Colors.white;
  static const Color onPrimaryBrand = Colors.white;

  // Neutral & Canvas
  static const Color canvas = Color(0xFFF8FAFC); // Scaffold background
  static const Color surfaceSubtle = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF); // Card & Input background
  static const Color onSurface = textPrimary;
  static const Color border = Color(0xFFE2E8F0); // Stroke border default
  static const Color outline = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFCBD5E1); // Divider / sub-border
  static const Color outlineVariant = Color(0xFFCBD5E1);
  static const Color textPrimary = Color(0xFF0F172A); // Heading & body utama
  static const Color textSecondary = Color(0xFF64748B); // Helper & label sekunder
  static const Color textMuted = Color(0xFF94A3B8); // Placeholder & hint

  // Semantic Status (API State Mapping)
  // 1. Success (Approved / Present / Paid)
  static const Color statusSuccess = Color(0xFF15803D);
  static const Color statusSuccessBg = Color(0xFFF0FDF4);
  static const Color statusSuccessBorder = Color(0xFFBBF7D0);

  // 2. Warning (Pending / Late / Draft)
  static const Color statusWarning = Color(0xFFB45309);
  static const Color statusWarningBg = Color(0xFFFFFBEB);
  static const Color statusWarningBorder = Color(0xFFFDE68A);

  // 3. Danger / Error (Rejected / Absent / Cancelled)
  static const Color statusDanger = Color(0xFFB91C1C);
  static const Color statusDangerBg = Color(0xFFFEF2F2);
  static const Color statusDangerBorder = Color(0xFFFECACA);
  static const Color error = statusDanger;
  static const Color onError = Colors.white;

  // 4. Info (Finalized / Permit / Audit)
  static const Color statusInfo = Color(0xFF0369A1);
  static const Color statusInfoBg = Color(0xFFF0F9FF);
  static const Color statusInfoBorder = Color(0xFFBAE6FD);
}
