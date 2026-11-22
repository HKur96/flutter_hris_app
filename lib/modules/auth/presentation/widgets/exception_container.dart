import 'package:flutter/material.dart';
import 'package:flutter_hris_app/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class ExceptionContainer extends StatelessWidget {
  final String errorMessage;
  final double marginTop;

  const ExceptionContainer({
    super.key,
    required this.errorMessage,
    this.marginTop = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: marginTop),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 14, color: AppColors.error),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 11,
                  height: 1.4,
                  color: AppColors.error,
                ),
                children: [TextSpan(text: errorMessage)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
