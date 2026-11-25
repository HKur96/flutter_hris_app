import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hris_app/core/config/extension.dart';
import 'package:flutter_hris_app/core/config/global.dart';
import 'package:flutter_hris_app/core/shared/app_secure_storage.dart';
import 'package:flutter_hris_app/modules/auth/data/repository/auth_repository_impl.dart';
import 'package:flutter_hris_app/modules/auth/domain/entity/setup_status.dart';
import 'package:flutter_hris_app/modules/auth/domain/entity/user.dart' as au;

class AuthProvider with ChangeNotifier {
  final _repository = AuthRepositoryImpl();

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
}
