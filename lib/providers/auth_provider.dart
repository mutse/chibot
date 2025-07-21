// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:chibot/models/user.dart';
import 'package:chibot/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  User? _currentUser;

  AuthProvider(this._authService) {
    _authService.authStateChanges.listen((user) {
      _currentUser = user;
      notifyListeners();
    });
    _authService.init(); // 初始化时加载用户状态
  }

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<void> register(String username, String password) async {
    try {
      await _authService.register(username, password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> login(String username, String password) async {
    try {
      await _authService.login(username, password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
  }
}
