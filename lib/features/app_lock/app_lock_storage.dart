import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppLockSecurityState {
  final int failedAttempts;
  final int lockoutLevel;
  final DateTime? lockedUntil;

  const AppLockSecurityState({
    this.failedAttempts = 0,
    this.lockoutLevel = 0,
    this.lockedUntil,
  });
}

abstract interface class AppLockStorage {
  Future<String?> readPin();
  Future<void> writePin(String pin);
  Future<void> deletePin();
  Future<AppLockSecurityState> readSecurityState();
  Future<void> writeSecurityState(AppLockSecurityState state);
}

class SecureAppLockStorage implements AppLockStorage {
  static const _pinKey = 'study_tracker_app_lock_pin';
  static const _securityStateKey = 'study_tracker_app_lock_security_state';

  final FlutterSecureStorage _storage;

  SecureAppLockStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> readPin() => _storage.read(key: _pinKey);

  @override
  Future<void> writePin(String pin) => _storage.write(key: _pinKey, value: pin);

  @override
  Future<void> deletePin() => _storage.delete(key: _pinKey);

  @override
  Future<AppLockSecurityState> readSecurityState() async {
    final value = await _storage.read(key: _securityStateKey);
    if (value == null) return const AppLockSecurityState();

    final fields = value.split('|');
    if (fields.length != 3) {
      throw const FormatException('Dữ liệu bảo vệ PIN không hợp lệ.');
    }
    final attempts = int.tryParse(fields[0]);
    final level = int.tryParse(fields[1]);
    final lockedUntil = fields[2].isEmpty ? null : DateTime.tryParse(fields[2]);
    if (attempts == null ||
        level == null ||
        attempts < 0 ||
        attempts >= 5 ||
        level < 0 ||
        level > 6 ||
        (fields[2].isNotEmpty && lockedUntil == null)) {
      throw const FormatException('Dữ liệu bảo vệ PIN không hợp lệ.');
    }
    return AppLockSecurityState(
      failedAttempts: attempts,
      lockoutLevel: level,
      lockedUntil: lockedUntil?.toUtc(),
    );
  }

  @override
  Future<void> writeSecurityState(AppLockSecurityState state) {
    final value = [
      state.failedAttempts,
      state.lockoutLevel,
      state.lockedUntil?.toUtc().toIso8601String() ?? '',
    ].join('|');
    return _storage.write(key: _securityStateKey, value: value);
  }
}
