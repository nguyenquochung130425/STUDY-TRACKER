import 'package:flutter/material.dart';
import '../core/services/auth_service.dart';
import '../models/user_model.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

/// Provider quản lý toàn bộ luồng xác thực và thông tin người dùng
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _currentUser != null;
  bool get isLoading => _status == AuthStatus.loading;

  AuthProvider() {
    checkAuthStatus();
  }

  /// Kiểm tra phiên đăng nhập đã lưu trong máy
  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await _authService.initializeDefaultUsers();
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        _status = AuthStatus.authenticated;
      } else {
        // Tự động kích hoạt tài khoản Demo ban đầu để trải nghiệm ngay
        try {
          final demoUser = await _authService.login(
            email: AuthService.demoEmail,
            password: AuthService.demoPassword,
          );
          _currentUser = demoUser;
          _status = AuthStatus.authenticated;
        } catch (_) {
          _currentUser = null;
          _status = AuthStatus.unauthenticated;
        }
      }
    } catch (e) {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  /// Đăng nhập
  Future<bool> login({required String email, required String password}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.login(email: email, password: password);
      _currentUser = user;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Đăng ký tài khoản
  Future<bool> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.register(
        displayName: displayName,
        email: email,
        password: password,
      );
      _currentUser = user;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Cập nhật hồ sơ cá nhân
  Future<bool> updateProfile({required String displayName}) async {
    if (_currentUser == null) return false;

    try {
      final updated = await _authService.updateProfile(
        id: _currentUser!.id,
        displayName: displayName,
      );
      _currentUser = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Đăng xuất
  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  /// Xóa lỗi hiển thị
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
