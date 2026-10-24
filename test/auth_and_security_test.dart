import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_tracker/core/services/auth_service.dart';
import 'package:study_tracker/core/services/security_service.dart';
import 'package:study_tracker/providers/auth_provider.dart';
import 'package:study_tracker/providers/security_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthService & AuthProvider Tests', () {
    test('AuthService registers new account and logs in successfully', () async {
      final authService = AuthService();
      await authService.initializeDefaultUsers();

      // Đăng ký tài khoản mới
      final newUser = await authService.register(
        displayName: 'Nguyễn Văn Test',
        email: 'test@example.com',
        password: 'password123',
      );
      expect(newUser.displayName, 'Nguyễn Văn Test');
      expect(newUser.email, 'test@example.com');

      // Đăng nhập lại với tài khoản vừa tạo
      final loggedInUser = await authService.login(
        email: 'test@example.com',
        password: 'password123',
      );
      expect(loggedInUser.id, newUser.id);
      expect(loggedInUser.displayName, 'Nguyễn Văn Test');

      // Đổi tên hồ sơ cá nhân
      final updatedUser = await authService.updateProfile(
        id: loggedInUser.id,
        displayName: 'Nguyễn Văn Updated',
      );
      expect(updatedUser.displayName, 'Nguyễn Văn Updated');

      // Đăng xuất
      await authService.logout();
      final currentUserAfterLogout = await authService.getCurrentUser();
      expect(currentUserAfterLogout, isNull);
    });

    test('AuthProvider state transitions work correctly', () async {
      final authProvider = AuthProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      // Ban đầu tự động nạp tài khoản demo
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.currentUser?.email, AuthService.demoEmail);

      // Đăng xuất
      await authProvider.logout();
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.currentUser, isNull);
      expect(authProvider.status, AuthStatus.unauthenticated);

      // Đăng nhập lại
      final loginSuccess = await authProvider.login(
        email: AuthService.demoEmail,
        password: AuthService.demoPassword,
      );
      expect(loginSuccess, isTrue);
      expect(authProvider.isAuthenticated, isTrue);
    });
  });

  group('SecurityService & SecurityProvider Tests', () {
    test('SecurityService PIN hashing and verification works', () async {
      final securityService = SecurityService();

      // Kiểm tra ban đầu chưa có PIN
      expect(await securityService.hasPinSet(), isFalse);
      expect(await securityService.isPinEnabled(), isFalse);

      // Thiết lập PIN mới
      await securityService.setPin('1234');
      expect(await securityService.hasPinSet(), isTrue);
      expect(await securityService.isPinEnabled(), isTrue);

      // Xác thực PIN đúng
      expect(await securityService.verifyPin('1234'), isTrue);

      // Xác thực PIN sai
      expect(await securityService.verifyPin('0000'), isFalse);

      // Tắt mã PIN
      await securityService.setPinEnabled(false);
      expect(await securityService.isPinEnabled(), isFalse);
      expect(await securityService.hasPinSet(), isTrue);

      // Xóa hoàn toàn mã PIN
      await securityService.removePin();
      expect(await securityService.hasPinSet(), isFalse);
    });

    test('SecurityProvider handles app lock and auto-lock state', () async {
      final securityProvider = SecurityProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      // Thiết lập PIN
      await securityProvider.setupNewPin('9876');
      expect(securityProvider.isPinEnabled, isTrue);
      expect(securityProvider.hasPinSet, isTrue);
      expect(securityProvider.isLocked, isFalse);

      // Kích hoạt khóa ứng dụng (khi chạy ngầm hoặc khóa thủ công)
      securityProvider.lockApp();
      expect(securityProvider.isLocked, isTrue);

      // Mở khóa với mã PIN sai
      final wrongUnlock = await securityProvider.verifyPin('1111');
      expect(wrongUnlock, isFalse);
      expect(securityProvider.isLocked, isTrue);
      expect(securityProvider.failedAttempts, 1);

      // Mở khóa với mã PIN đúng
      final correctUnlock = await securityProvider.verifyPin('9876');
      expect(correctUnlock, isTrue);
      expect(securityProvider.isLocked, isFalse);
      expect(securityProvider.failedAttempts, 0);
    });
  });
}
