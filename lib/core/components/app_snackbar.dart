import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

enum SnackBarType { success, error, warning, info }

class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    Color bg;
    Color fg;
    IconData icon;

    switch (type) {
      case SnackBarType.success:
        bg = const Color(0xFF065F46); // Emerald 800
        fg = Colors.white;
        icon = Icons.check_circle_rounded;
        break;
      case SnackBarType.error:
        bg = const Color(0xFF991B1B); // Red 800
        fg = Colors.white;
        icon = Icons.cancel_rounded;
        break;
      case SnackBarType.warning:
        bg = const Color(0xFF92400E); // Amber 800
        fg = Colors.white;
        icon = Icons.warning_rounded;
        break;
      case SnackBarType.info:
        bg = AppColors.primary;
        fg = Colors.white;
        icon = Icons.info_rounded;
        break;
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bg,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
      ),
    );
  }
}
