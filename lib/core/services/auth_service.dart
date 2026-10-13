import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../../models/user_model.dart';

/// Dịch vụ Xác thực người dùng (Auth Service)
/// Hỗ trợ lưu trữ cục bộ, dễ dàng hoán đổi sang Firebase Auth hoặc REST API
class AuthService {
  // Tài khoản demo mặc định ban đầu
  static const String demoEmail = 'demo@studytracker.com';
  static const String demoPassword = 'password123';

  /// Khởi tạo dữ liệu người dùng ban đầu nếu chưa có
  Future<void> initializeDefaultUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final accountsRaw = prefs.getString(AppConstants.keyUserAccounts);

    if (accountsRaw == null) {
      final defaultAccounts = [
        {
          'user': UserModel(
            id: 'user_demo_1',
            email: demoEmail,
            displayName: 'Sinh viên Demo',
            createdAt: DateTime.now().subtract(const Duration(days: 30)),
          ).toJson(),
          'password': demoPassword,
        }
      ];
      await prefs.setString(
        AppConstants.keyUserAccounts,
        jsonEncode(defaultAccounts),
      );
    }
  }

  /// Lấy thông tin phiên đăng nhập người dùng hiện tại
  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userRaw = prefs.getString(AppConstants.keyCurrentUser);
    if (userRaw != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(userRaw);
        return UserModel.fromJson(decoded);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Đăng nhập bằng Email và Mật khẩu
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final prefs = await SharedPreferences.getInstance();

    await initializeDefaultUsers();
    final accountsRaw = prefs.getString(AppConstants.keyUserAccounts);
    if (accountsRaw != null) {
      final List decoded = jsonDecode(accountsRaw);
      for (final item in decoded) {
        final Map<String, dynamic> acc = item as Map<String, dynamic>;
        final userMap = acc['user'] as Map<String, dynamic>;
        final accEmail = (userMap['email'] as String).toLowerCase();
        final accPassword = acc['password'] as String;

        if (accEmail == normalizedEmail && accPassword == password) {
          final user = UserModel.fromJson(userMap);
          await prefs.setString(AppConstants.keyCurrentUser, jsonEncode(user.toJson()));
          return user;
        }
      }
    }

    throw Exception('Email hoặc mật khẩu không chính xác');
  }

  /// Đăng ký tài khoản mới
  Future<UserModel> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final prefs = await SharedPreferences.getInstance();

    await initializeDefaultUsers();
    final accountsRaw = prefs.getString(AppConstants.keyUserAccounts) ?? '[]';
    final List decoded = jsonDecode(accountsRaw);

    // Kiểm tra xem email đã tồn tại chưa
    for (final item in decoded) {
      final userMap = (item as Map<String, dynamic>)['user'] as Map<String, dynamic>;
      if ((userMap['email'] as String).toLowerCase() == normalizedEmail) {
        throw Exception('Email này đã được sử dụng. Vui lòng đăng nhập.');
      }
    }

    // Tạo tài khoản mới
    final newUser = UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: normalizedEmail,
      displayName: displayName.trim(),
      createdAt: DateTime.now(),
    );

    decoded.add({
      'user': newUser.toJson(),
      'password': password,
    });

    await prefs.setString(AppConstants.keyUserAccounts, jsonEncode(decoded));
    await prefs.setString(AppConstants.keyCurrentUser, jsonEncode(newUser.toJson()));

    return newUser;
  }

  /// Cập nhật thông tin cá nhân (Profile)
  Future<UserModel> updateProfile({
    required String id,
    required String displayName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUser = await getCurrentUser();
    if (currentUser == null) throw Exception('Chưa đăng nhập');

    final updated = currentUser.copyWith(displayName: displayName.trim());
    await prefs.setString(AppConstants.keyCurrentUser, jsonEncode(updated.toJson()));

    // Cập nhật trong danh sách accounts
    final accountsRaw = prefs.getString(AppConstants.keyUserAccounts);
    if (accountsRaw != null) {
      final List decoded = jsonDecode(accountsRaw);
      for (int i = 0; i < decoded.length; i++) {
        final acc = decoded[i] as Map<String, dynamic>;
        final userMap = acc['user'] as Map<String, dynamic>;
        if (userMap['id'] == id) {
          acc['user'] = updated.toJson();
          break;
        }
      }
      await prefs.setString(AppConstants.keyUserAccounts, jsonEncode(decoded));
    }

    return updated;
  }

  /// Đăng xuất khỏi hệ thống
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyCurrentUser);
  }
}
