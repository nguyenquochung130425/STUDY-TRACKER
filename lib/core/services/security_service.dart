import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Dịch vụ quản lý mã PIN & Bảo mật lưu trữ
class SecurityService {
  static const String _salt = 'StudyTracker_Secure_Salt_2026';

  /// Mã hóa một chiều (hashing) mã PIN với Salt để chống nhìn trộm dữ liệu
  String hashPin(String pin) {
    final combined = '$_salt:${pin.trim()}:$_salt';
    // Triển khai băm đa tầng với chuỗi salt và base64 transform
    final bytes = utf8.encode(combined);
    int h1 = 0x811c9dc5;
    int h2 = 0x9e3779b9;
    for (final b in bytes) {
      h1 = ((h1 ^ b) * 0x01000193) & 0xFFFFFFFF;
      h2 = ((h2 ^ b) * 0x27d4eb2f) & 0xFFFFFFFF;
    }
    final digest = '${h1.toRadixString(16).padLeft(8, '0')}-${h2.toRadixString(16).padLeft(8, '0')}';
    return base64Url.encode(utf8.encode(digest));
  }

  /// Kiểm tra xem người dùng đã bật mã PIN chưa
  Future<bool> isPinEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyPinEnabled) ?? false;
  }

  /// Kiểm tra xem mã PIN đã từng được thiết lập chưa
  Future<bool> hasPinSet() async {
    final prefs = await SharedPreferences.getInstance();
    final savedHash = prefs.getString(AppConstants.keyPinHash);
    return savedHash != null && savedHash.isNotEmpty;
  }

  /// Lưu mã PIN mới
  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final hashed = hashPin(pin);
    await prefs.setString(AppConstants.keyPinHash, hashed);
    await prefs.setBool(AppConstants.keyPinEnabled, true);
  }

  /// Xác thực mã PIN nhập vào
  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final savedHash = prefs.getString(AppConstants.keyPinHash);
    if (savedHash == null) return false;
    return savedHash == hashPin(pin);
  }

  /// Bật hoặc tắt mã PIN
  Future<void> setPinEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyPinEnabled, enabled);
  }

  /// Xóa mã PIN hoàn toàn
  Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyPinHash);
    await prefs.setBool(AppConstants.keyPinEnabled, false);
  }

  /// Kiểm tra cấu hình tự động khóa khi xuống background
  Future<bool> isAutoLockOnBackground() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyAutoLock) ?? true;
  }

  /// Cấu hình tự động khóa khi xuống background
  Future<void> setAutoLockOnBackground(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyAutoLock, enabled);
  }
}
