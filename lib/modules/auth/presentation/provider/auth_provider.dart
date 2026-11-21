import 'package:flutter/material.dart';
import 'package:flutter_hris_app/modules/auth/data/repository/auth_repository_impl.dart';
import 'package:flutter_hris_app/modules/auth/domain/entity/user.dart';

class AuthProvider with ChangeNotifier {
  final _repository = AuthRepositoryImpl();

  bool _isLoadingLogin = false;
  String? _errorMessage;
  User? _user;

  bool get isLoadingLogin => _isLoadingLogin;
  String? get errorMessage => _errorMessage;
  User? get user => _user;

  Future<User?> login(String email, String password) async {
    try {
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
      return null;
    } finally {
      _isLoadingLogin = false;
      notifyListeners();
    }
  }
}
