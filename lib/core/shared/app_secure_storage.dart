import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hris_app/modules/auth/data/model/user_model.dart';
import 'package:flutter_hris_app/modules/auth/domain/entity/user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppSecureStorage {
  // Private constructor to prevent external instantiation.
  AppSecureStorage._();

  // The single instance of the class.
  static final AppSecureStorage _instance = AppSecureStorage._();

  // Factory constructor to provide access to the singleton instance.
  factory AppSecureStorage() => _instance;

  static const _storage = FlutterSecureStorage(aOptions: AndroidOptions());

  // keys
  static const String _token = 'app-token';
  static const String _user = 'app-user';
  static const String _deploymentId = 'app-deployment-id';

  Future<void> writeDeploymentId(String deploymentId) async {
    await _storage.write(key: _deploymentId, value: deploymentId);
  }

  Future<String?> readDeploymentId() async {
    return await _storage.read(key: _deploymentId);
  }

  /// Getter currentUser untuk kemudahan pengecekan sesi login
  Future<User?> get currentUser => readUser();

  Future<void> writeToken(String token) async {
    await _storage.write(key: _token, value: token);
  }

  // read token
  Future<String?> readToken() async {
    return await _storage.read(key: _token);
  }

  // delete token
  Future<void> deleteToken() async {
    await _storage.delete(key: _token);
  }

  // write user
  Future<void> writeUser(UserModel user) async {
    try {
      await _storage.write(key: _user, value: jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('Error writing user to secure storage: $e');
    }
  }

  // read user
  Future<User?> readUser() async {
    try {
      final String? user = await _storage.read(key: _user);
      return UserModel.fromJson(jsonDecode(user!));
    } catch (e) {
      return null;
    }
  }

  // delete user
  Future<void> deleteUser() async {
    await _storage.delete(key: _user);
  }

  // clear all credentials (logout)
  Future<void> clearAll() async {
    await deleteToken();
    await deleteUser();
  }
}
