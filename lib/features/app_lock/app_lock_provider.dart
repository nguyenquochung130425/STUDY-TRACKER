import 'package:flutter/foundation.dart';

import 'app_lock_storage.dart';

class AppLockProvider extends ChangeNotifier {
  static const _maxFailedAttempts = 5;
  static const _maxLockoutSeconds = 15 * 60;

  final AppLockStorage _storage;
  final DateTime Function() _clock;

  bool _initialized = false;
  bool _enabled = false;
  bool _isLocked = false;
  String? _pin;
  String? _initializationError;
  int _failedAttempts = 0;
  int _lockoutLevel = 0;
  DateTime? _lockedUntil;

  AppLockProvider({AppLockStorage? storage, DateTime Function()? clock})
    : _storage = storage ?? SecureAppLockStorage(),
      _clock = clock ?? DateTime.now;

  bool get initialized => _initialized;
  bool get isEnabled => _enabled;
  bool get isLocked => _isLocked;
  String? get initializationError => _initializationError;
  int get attemptsRemaining => _maxFailedAttempts - _failedAttempts;
  Duration get lockoutRemaining {
    final lockedUntil = _lockedUntil;
    if (lockedUntil == null) return Duration.zero;
    final remaining = lockedUntil.difference(_clock());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isTemporarilyLocked => lockoutRemaining > Duration.zero;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _pin = await _storage.readPin();
      final securityState = await _storage.readSecurityState();
      _failedAttempts = securityState.failedAttempts;
      _lockoutLevel = securityState.lockoutLevel;
      _lockedUntil = securityState.lockedUntil;
      _enabled = _pin != null;
      _isLocked = _enabled;
      _initializationError = null;
      _initialized = true;
      notifyListeners();
    } catch (error) {
      _initializationError = error.toString();
      _isLocked = true;
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> retryInitialize() async {
    _initialized = false;
    _initializationError = null;
    notifyListeners();
    await initialize();
  }

  Future<void> enable(String pin) async {
    _validatePin(pin);
    await _storage.writePin(pin);
    await _storage.writeSecurityState(const AppLockSecurityState());
    _pin = pin;
    _enabled = true;
    _isLocked = false;
    _initializationError = null;
    notifyListeners();
  }

  Future<bool> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    if (!await verifyPin(currentPin)) return false;
    _validatePin(newPin);
    await _storage.writePin(newPin);
    await _storage.writeSecurityState(const AppLockSecurityState());
    _pin = newPin;
    _failedAttempts = 0;
    _lockoutLevel = 0;
    _lockedUntil = null;
    notifyListeners();
    return true;
  }

  Future<bool> disable(String currentPin) async {
    if (!await verifyPin(currentPin)) return false;
    await _storage.deletePin();
    await _storage.writeSecurityState(const AppLockSecurityState());
    _pin = null;
    _enabled = false;
    _isLocked = false;
    notifyListeners();
    return true;
  }

  Future<bool> verifyPin(String pin) async {
    if (isTemporarilyLocked) return false;
    if (_lockedUntil != null) {
      _lockedUntil = null;
      await _persistSecurityState();
    }
    final savedPin = _pin ?? await _storage.readPin();
    if (savedPin == null) return false;
    if (!_matches(pin, savedPin)) {
      _failedAttempts++;
      if (_failedAttempts >= _maxFailedAttempts) {
        _failedAttempts = 0;
        if (_lockoutLevel < 6) _lockoutLevel++;
        final seconds = (30 * (1 << (_lockoutLevel - 1))).clamp(
          30,
          _maxLockoutSeconds,
        );
        _lockedUntil = _clock().add(Duration(seconds: seconds));
      }
      await _persistSecurityState();
      notifyListeners();
      return false;
    }
    _pin = savedPin;
    _enabled = true;
    _isLocked = false;
    _failedAttempts = 0;
    _lockoutLevel = 0;
    _lockedUntil = null;
    await _persistSecurityState();
    notifyListeners();
    return true;
  }

  Future<void> _persistSecurityState() => _storage.writeSecurityState(
    AppLockSecurityState(
      failedAttempts: _failedAttempts,
      lockoutLevel: _lockoutLevel,
      lockedUntil: _lockedUntil,
    ),
  );

  void lock() {
    if (!_enabled || _isLocked) return;
    _isLocked = true;
    notifyListeners();
  }

  static bool isValidPin(String pin) =>
      pin.length == 6 && RegExp(r'^\d{6}$').hasMatch(pin);

  static void _validatePin(String pin) {
    if (!isValidPin(pin)) {
      throw ArgumentError.value(pin, 'pin', 'PIN phải gồm đúng 6 chữ số.');
    }
  }

  static bool _matches(String candidate, String saved) {
    if (candidate.length != saved.length) return false;
    var difference = 0;
    for (var index = 0; index < candidate.length; index++) {
      difference |= candidate.codeUnitAt(index) ^ saved.codeUnitAt(index);
    }
    return difference == 0;
  }
}
