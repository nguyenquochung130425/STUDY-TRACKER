import 'package:flutter/material.dart';
import '../core/services/security_service.dart';

/// Provider quản lý cơ chế bảo mật: Mã PIN, Khóa App và Khóa khi chạy ngầm
class SecurityProvider extends ChangeNotifier {
  final SecurityService _securityService = SecurityService();

  bool _isPinEnabled = false;
  bool _hasPinSet = false;
  bool _isLocked = false;
  bool _autoLockOnBackground = true;
  int _failedAttempts = 0;
  bool _isLoading = true;

  bool get isPinEnabled => _isPinEnabled;
  bool get hasPinSet => _hasPinSet;
  bool get isLocked => _isLocked;
  bool get autoLockOnBackground => _autoLockOnBackground;
  int get failedAttempts => _failedAttempts;
  bool get isLoading => _isLoading;

  SecurityProvider() {
    _initSecurity();
  }

  Future<void> _initSecurity() async {
    _isLoading = true;
    notifyListeners();

    _isPinEnabled = await _securityService.isPinEnabled();
    _hasPinSet = await _securityService.hasPinSet();
    _autoLockOnBackground = await _securityService.isAutoLockOnBackground();

    // Nếu người dùng đã kích hoạt mã PIN, tự động khóa khi khởi động app
    if (_isPinEnabled && _hasPinSet) {
      _isLocked = true;
    } else {
      _isLocked = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Khóa ứng dụng ngay lập tức
  void lockApp() {
    if (_isPinEnabled && _hasPinSet && !_isLocked) {
      _isLocked = true;
      notifyListeners();
    }
  }

  /// Mở khóa ứng dụng
  void unlockApp() {
    _isLocked = false;
    _failedAttempts = 0;
    notifyListeners();
  }

  /// Xác thực mã PIN
  Future<bool> verifyPin(String pin) async {
    final isValid = await _securityService.verifyPin(pin);
    if (isValid) {
      _isLocked = false;
      _failedAttempts = 0;
      notifyListeners();
      return true;
    } else {
      _failedAttempts++;
      notifyListeners();
      return false;
    }
  }

  /// Thiết lập mã PIN mới
  Future<void> setupNewPin(String pin) async {
    await _securityService.setPin(pin);
    _isPinEnabled = true;
    _hasPinSet = true;
    _isLocked = false;
    _failedAttempts = 0;
    notifyListeners();
  }

  /// Bật / Tắt tính năng bảo mật bằng mã PIN
  Future<void> setPinEnabled(bool enabled) async {
    if (enabled && !_hasPinSet) {
      // Chưa thiết lập PIN thì không thể chỉ bật cờ
      return;
    }
    await _securityService.setPinEnabled(enabled);
    _isPinEnabled = enabled;
    if (!enabled) {
      _isLocked = false;
    }
    notifyListeners();
  }

  /// Tắt và xóa hoàn toàn mã PIN
  Future<void> disableAndRemovePin() async {
    await _securityService.removePin();
    _isPinEnabled = false;
    _hasPinSet = false;
    _isLocked = false;
    notifyListeners();
  }

  /// Cập nhật tùy chọn tự động khóa khi app xuống background
  Future<void> setAutoLockOnBackground(bool enabled) async {
    await _securityService.setAutoLockOnBackground(enabled);
    _autoLockOnBackground = enabled;
    notifyListeners();
  }
}
