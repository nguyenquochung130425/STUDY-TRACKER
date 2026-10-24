import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_tracker/features/app_lock/app_lock_storage.dart';
import 'package:study_tracker/main.dart';

class _MemoryAppLockStorage implements AppLockStorage {
  AppLockSecurityState _securityState = const AppLockSecurityState();

  @override
  Future<String?> readPin() async => null;

  @override
  Future<AppLockSecurityState> readSecurityState() async => _securityState;

  @override
  Future<void> writePin(String pin) async {}

  @override
  Future<void> deletePin() async {}

  @override
  Future<void> writeSecurityState(AppLockSecurityState state) async {
    _securityState = state;
  }
}

void main() {
  testWidgets('StudyTrackerApp loads successfully test', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      StudyTrackerApp(appLockStorage: _MemoryAppLockStorage()),
    );
    await tester.pumpAndSettle();

    // Xác nhận giao diện hiển thị đúng tiêu đề chính
    expect(find.textContaining('Study Tracker'), findsOneWidget);
    expect(find.text('Học tập'), findsOneWidget);
    expect(find.text('Thống kê'), findsOneWidget);
    expect(find.text('Nhiệm vụ'), findsOneWidget);

    await tester.tap(find.text('Thống kê'));
    await tester.pumpAndSettle();
    expect(find.text('Điểm số theo môn'), findsOneWidget);
    expect(find.text('Chưa có điểm'), findsWidgets);
  });
}
