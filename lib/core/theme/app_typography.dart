import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Skala tipografi mobile-first KaryaHR sesuai Tahap 1 — Design Foundation.
/// Menggunakan font Plus Jakarta Sans dan JetBrains Mono untuk kode/ID.
class AppTypography {
  AppTypography._();

  // Screen Title / Headline: 20px / 28px / SemiBold (600)
  static TextStyle headline = GoogleFonts.plusJakartaSans(
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  // Section Header / Dialog Title: 16px / 24px / SemiBold (600)
  static TextStyle sectionHeader = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  // Body Regular: 14px / 20px / Regular (400)
  static TextStyle bodyRegular = GoogleFonts.inter(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  // Body Medium (Label / Value): 14px / 20px / Medium (500)
  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  // Body SemiBold: 14px / 20px / SemiBold (600)
  static TextStyle bodySemiBold = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Caption & Helper Text: 12px / 16px / Regular (400)
  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // Caption Medium: 12px / 16px / Medium (500)
  static TextStyle captionMedium = GoogleFonts.inter(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // Badge & Metadata Label: 11px / 14px / SemiBold (600)
  static TextStyle badge = GoogleFonts.plusJakartaSans(
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  // Micro Label: 10px / 12px / Medium (500)
  static TextStyle micro = GoogleFonts.inter(
    fontSize: 10,
    height: 12 / 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // Code / Monospace Text: 12px / JetBrains Mono
  static TextStyle code = GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
}
