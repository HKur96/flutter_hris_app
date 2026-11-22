
import 'package:flutter/material.dart';

class Validators {
  static String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'email wajib diisi';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'email tidak valid';
    }
    return null;
  }

  static String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'password wajib diisi';
    }

    if (value.length < 8) {
      return 'password minimal 8 karakter';
    }
    return null;
  }

  static String? confirmPasswordValidator(
    String? value,
    TextEditingController passwordController,
  ) {
    if (value == null || value.isEmpty) {
      return 'password wajib diisi';
    }

    if (value != passwordController.text) {
      return 'password tidak sesuai';
    }

    return null;
  }
}
