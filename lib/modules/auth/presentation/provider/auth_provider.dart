import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hris_app/core/config/extension.dart';
import 'package:flutter_hris_app/core/config/global.dart';
import 'package:flutter_hris_app/core/shared/app_secure_storage.dart';
import 'package:flutter_hris_app/modules/auth/data/model/user_model.dart';
import 'package:flutter_hris_app/modules/auth/data/repository/auth_repository_impl.dart';
import 'package:flutter_hris_app/modules/auth/domain/repository/auth_repository.dart';
import 'package:flutter_hris_app/modules/auth/domain/entity/setup_status.dart';
import 'package:flutter_hris_app/modules/auth/domain/entity/user.dart' as au;

class AuthProvider with ChangeNotifier {
  final AuthRepository _repository;

  AuthProvider({AuthRepository? repository})
    : _repository = repository ?? AuthRepositoryImpl();

  bool _isLoadingLogin = false;
  String? _errorMessage;
  au.User? _user;
  SetupStatus? _setupStatus;
  String? _loadingMessage;

  bool get isLoadingLogin => _isLoadingLogin;
  String? get errorMessage => _errorMessage;
  au.User? get user => _user;
  SetupStatus? get setupStatus => _setupStatus;
  String? get loadingMessage => _loadingMessage;

  Future<au.User?> getCurrentUser() async {
    try {
      _loadingMessage = 'Sedang menyiapkan data Anda';
      _errorMessage = null;
      notifyListeners();

      _user = await AppSecureStorage().currentUser;

      return _user;
    } catch (e) {
      return null;
    } finally {
      _loadingMessage = null;
      notifyListeners();
    }
  }

  Future<SetupStatus?> checkSetupStatus({bool showLoadingDialog = true}) async {
    var completer = Completer();
    try {
      _loadingMessage = 'Sedang menyiapkan data Anda';
      if (showLoadingDialog && gNavigatorKey.currentContext != null) {
        gNavigatorKey.currentContext!.showLoadingDialog(
          dismissCompleter: completer,
          text: 'Sedang menyiapkan data Anda...',
        );
      }
      _errorMessage = null;
      notifyListeners();

      final res = await _repository.checkSetupStatus();

      res.fold(
        (l) {
          _errorMessage = l.errorMessage;
        },
        (r) {
          _setupStatus = r;
        },
      );

      return _setupStatus;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _loadingMessage = null;
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }

  Future<au.User?> setupOwner(String email, String password) async {
    try {
      _errorMessage = null;
      _isLoadingLogin = true;
      notifyListeners();

      final res = await _repository.setupInitialOwner(email, password);

      res.fold(
        (l) {
          _errorMessage = l.errorMessage;
        },
        (r) {
          _user = r;
        },
      );

      return _user;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoadingLogin = false;
      notifyListeners();
    }
  }

  Future<au.User?> login(String email, String password) async {
    try {
      _errorMessage = null;
      _isLoadingLogin = true;
      notifyListeners();

      final res = await _repository.loginUser(email, password);

      res.fold(
        (l) {
          _errorMessage = l.errorMessage;
        },
        (r) {
          _user = r;
        },
      );

      return _user;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoadingLogin = false;
      notifyListeners();
    }
  }

  /// Memperbarui nama toko / usaha & opsi sistem shift milik akun Admin atau Owner via PUT /api/v1/auth/store
  Future<bool> updateStoreName(String newStoreName, {bool? isShift}) async {
    if (_user == null) return false;
    try {
      _errorMessage = null;
      notifyListeners();

      final res = await _repository.updateStoreSettings(
        newStoreName,
        isShift: isShift,
      );

      bool isSuccess = true;
      String finalName = newStoreName;

      res.fold(
        (l) {
          _errorMessage = l.errorMessage;
          isSuccess = false;
        },
        (r) {
          finalName = r;
          isSuccess = true;
        },
      );

      if (!isSuccess) {
        notifyListeners();
        return false;
      }

      final updatedUser = _user!.copyWith(
        storeName: finalName,
        isShift: isShift ?? _user!.isShift,
        updatedAt: DateTime.now(),
      );
      _user = updatedUser;

      final model = UserModel(
        id: updatedUser.id,
        name: updatedUser.name,
        employeeId: updatedUser.employeeId,
        email: updatedUser.email,
        role: updatedUser.role,
        isActive: updatedUser.isActive,
        storeName: updatedUser.storeName,
        isShift: updatedUser.isShift,
        createdAt: updatedUser.createdAt,
        updatedAt: updatedUser.updatedAt,
        nik: updatedUser.nik,
        position: updatedUser.position,
        department: updatedUser.department,
      );
      try {
        await AppSecureStorage().writeUser(model);
      } catch (_) {}
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Memperbarui kata sandi mandiri via POST /api/v1/auth/change-password
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    var completer = Completer();
    try {
      gNavigatorKey.currentContext!.showLoadingDialog(
        dismissCompleter: completer,
        text: 'Sedang mengubah password Anda',
      );
      _errorMessage = null;
      notifyListeners();

      final res = await _repository.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      final bool isSuccess = res.fold(
        (l) {
          _errorMessage = l.errorMessage;
          notifyListeners();
          return false;
        },
        (r) {
          notifyListeners();
          return r;
        },
      );
      return isSuccess;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      if (!completer.isCompleted) completer.complete();
    }
  }

  /// Sinkronisasi profil pengguna terbaru via GET /api/v1/auth/me
  Future<void> refreshProfile() async {
    try {
      final res = await _repository.getMe();
      res.fold((l) => null, (r) {
        _user = r;
        notifyListeners();
      });
    } catch (_) {}
  }

  /// Menghapus sesi login dan kredensial pengguna
  Future<void> logout() async {
    try {
      await AppSecureStorage().clearAll();
    } catch (_) {}
    _user = null;
    notifyListeners();
  }
}
