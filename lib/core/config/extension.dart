// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flash/flash_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

extension ScreenUtil on BuildContext {
  Future<T?> showLoadingDialog<T>({
    required Completer<T>? dismissCompleter,
    Duration transitionDuration = const Duration(milliseconds: 250),
    Duration reverseTransitionDuration = const Duration(milliseconds: 200),
    Color barrierColor = const Color(0x8A000000),
    double? barrierBlur,
    Curve barrierCurve = Curves.ease,
    String? text,
  }) {
    return showModalFlash(
      transitionDuration: transitionDuration,
      reverseTransitionDuration: reverseTransitionDuration,
      barrierColor: barrierColor,
      barrierBlur: barrierBlur,
      barrierCurve: barrierCurve,
      dismissCompleter: dismissCompleter,
      builder: (context, controller) {
        return PopScope(
          canPop: false,
          child: FadeTransition(
            opacity: controller.controller,
            child: Align(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LoadingAnimationWidget.progressiveDots(
                      color: Colors.white,
                      size: MediaQuery.of(context).size.width * 0.2,
                    ),
                    if (text != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        text,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
