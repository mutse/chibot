// lib/services/auth_service.dart
import 'dart:async';
import 'package:chibot/core/shared_preferences_manager.dart';
import 'package:chibot/models/user.dart';

class AuthService {
  
  User? _currentUser;
  final StreamController<User?> _authStateController = StreamController<User?>.broadcast();

  AuthService();

  Stream<User?> get authStateChanges => _authStateController.stream;

  User? get currentUser => _currentUser;

  // 初始化时尝试加载当前用户
  Future<void> init() async {
    final userId = await SharedPreferencesManager.getString('current_user_id');
    if (userId != null) {
      // 实际应用中，这里会从后端获取完整的用户信息
      // 暂时模拟一个用户
      _currentUser = User(id: userId, username: 'User_$userId', avatarUrl: 'https://example.com/default_avatar.png');
      _authStateController.add(_currentUser);
    } else {
      _authStateController.add(null);
    }
  }

  Future<User> register(String username, String password) async {
    // 模拟注册逻辑，实际应调用后端API
    await Future.delayed(const Duration(seconds: 1)); // 模拟网络延迟
    final newUser = User(id: 'user_${DateTime.now().millisecondsSinceEpoch}', username: username);
    _currentUser = newUser;
    await SharedPreferencesManager.setString('current_user_id', newUser.id);
    _authStateController.add(_currentUser);
    return newUser;
  }

  Future<User> login(String username, String password) async {
    // 模拟登录逻辑，实际应调用后端API
    await Future.delayed(const Duration(seconds: 1)); // 模拟网络延迟
    if (username == 'test' && password == 'password') {
      final loggedInUser = User(id: 'test_user_id', username: username, avatarUrl: 'https://example.com/test_avatar.png');
      _currentUser = loggedInUser;
      await SharedPreferencesManager.setString('current_user_id', loggedInUser.id);
      _authStateController.add(_currentUser);
      return loggedInUser;
    } else {
      throw Exception('Invalid credentials');
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    await SharedPreferencesManager.remove('current_user_id');
    _authStateController.add(null);
  }

  void dispose() {
    _authStateController.close();
  }
}
