import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:study_tracker/features/app_lock/app_lock_gate.dart';
import 'package:study_tracker/features/app_lock/app_lock_provider.dart';
import 'package:study_tracker/features/app_lock/app_lock_storage.dart';

class MemoryAppLockStorage implements AppLockStorage {
  String? pin;

  @override
  Future<String?> readPin() async => pin;

  @override
  Future<void> writePin(String pin) async {
    this.pin = pin;
  }

  @override
  Future<void> deletePin() async {
    pin = null;
  }

  @override
  Future<AppLockSecurityState> readSecurityState() async =>
      securityState ?? const AppLockSecurityState();

  @override
  Future<void> writeSecurityState(AppLockSecurityState state) async {
    securityState = state;
  }

  AppLockSecurityState? securityState;
}

void main() {
  group('AppLockProvider', () {
    test('enables PIN and requires it again after relaunch', () async {
      final storage = MemoryAppLockStorage();
      final appLock = AppLockProvider(storage: storage);

      await appLock.initialize();
      expect(appLock.isEnabled, isFalse);
      await appLock.enable('123456');
      expect(appLock.isEnabled, isTrue);
      expect(appLock.isLocked, isFalse);

      final relaunchedAppLock = AppLockProvider(storage: storage);
      await relaunchedAppLock.initialize();
      expect(relaunchedAppLock.isEnabled, isTrue);
      expect(relaunchedAppLock.isLocked, isTrue);
    });

    test(
      'only unlocks with the correct PIN and relocks on lifecycle event',
      () async {
        final appLock = AppLockProvider(storage: MemoryAppLockStorage());
        await appLock.initialize();
        await appLock.enable('123456');
        appLock.lock();

        expect(await appLock.verifyPin('000000'), isFalse);
        expect(appLock.isLocked, isTrue);
        expect(await appLock.verifyPin('123456'), isTrue);
        expect(appLock.isLocked, isFalse);

        appLock.lock();
        expect(appLock.isLocked, isTrue);
      },
    );

    test('requires six digits and validates current PIN for changes', () async {
      final appLock = AppLockProvider(storage: MemoryAppLockStorage());
      await appLock.initialize();

      await expectLater(appLock.enable('12345'), throwsArgumentError);
      await appLock.enable('123456');

      expect(
        await appLock.changePin(currentPin: '000000', newPin: '654321'),
        isFalse,
      );
      expect(
        await appLock.changePin(currentPin: '123456', newPin: '654321'),
        isTrue,
      );
      expect(await appLock.verifyPin('654321'), isTrue);
      expect(await appLock.disable('123456'), isFalse);
      expect(await appLock.disable('654321'), isTrue);
      expect(appLock.isEnabled, isFalse);
    });

    test(
      'persists failed attempts and throttles repeated wrong PINs',
      () async {
        var now = DateTime(2026, 10, 24, 12);
        final storage = MemoryAppLockStorage()..pin = '123456';
        final appLock = AppLockProvider(storage: storage, clock: () => now);
        await appLock.initialize();

        for (var attempt = 0; attempt < 4; attempt++) {
          expect(await appLock.verifyPin('000000'), isFalse);
        }
        expect(appLock.attemptsRemaining, 1);

        expect(await appLock.verifyPin('000000'), isFalse);
        expect(appLock.isTemporarilyLocked, isTrue);
        expect(await appLock.verifyPin('123456'), isFalse);

        final restartedAppLock = AppLockProvider(
          storage: storage,
          clock: () => now,
        );
        await restartedAppLock.initialize();
        expect(restartedAppLock.isTemporarilyLocked, isTrue);

        now = now.add(const Duration(seconds: 31));
        expect(await restartedAppLock.verifyPin('123456'), isTrue);
        expect(restartedAppLock.isTemporarilyLocked, isFalse);
      },
    );

    testWidgets('locks the Flutter UI when app lifecycle leaves active', (
      tester,
    ) async {
      final storage = MemoryAppLockStorage()..pin = '123456';
      final appLock = AppLockProvider(storage: storage);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppLockProvider>.value(
          value: appLock,
          child: const MaterialApp(
            home: AppLockGate(child: Text('Private content')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ứng dụng đã khóa'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.text('Mở khóa'));
      await tester.pumpAndSettle();
      expect(find.text('Private content'), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      expect(appLock.isLocked, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('Ứng dụng đã khóa'), findsOneWidget);
    });
  });
}
