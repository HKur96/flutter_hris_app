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

  static String? regularValidator(String label, String? val) {
    if (val == null || val.trim().isEmpty) {
      return '$label wajib diisi';
    }

    return null;
  }

  static String? phoneValidator(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Nomor telepon wajib diisi';
    }

    if (!RegExp(r'^[0-9]{10,13}$').hasMatch(val)) {
      return 'Nomor telepon harus 10 sampai 13 digit';
    }

    return null;
  }

  static String? nikValidator(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'NIK wajib diisi';
    }
    if (val.trim().length != 16) {
      return 'NIK harus tepat 16 digit';
    }
    return null;
  }
}
