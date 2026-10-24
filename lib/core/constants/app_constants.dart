/// Các hằng số cấu hình của ứng dụng
class AppConstants {
  static const String appName = 'Study Tracker';
  static const String appVersion = '1.0.0';

  // SharedPreferences Keys
  static const String keyThemeMode = 'app_theme_mode';
  static const String keyCurrentUser = 'auth_current_user';
  static const String keyUserAccounts = 'auth_registered_accounts';
  static const String keyPinHash = 'security_pin_hash';
  static const String keyPinEnabled = 'security_pin_enabled';
  static const String keyAutoLock = 'security_auto_lock_background';

  // Security Defaults
  static const int pinLength = 4;
  static const int maxPinAttempts = 5;
}
