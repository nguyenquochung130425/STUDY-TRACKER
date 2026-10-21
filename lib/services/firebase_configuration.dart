import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseConfiguration {
  static const _configured = bool.fromEnvironment('FIREBASE_CONFIGURED');
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _messagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const _storageBucket =
      String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

  static bool get isConfigured => _configured;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return FirebaseOptions(
        apiKey: _apiKey,
        appId: const String.fromEnvironment('FIREBASE_WEB_APP_ID'),
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        authDomain: const String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
        storageBucket: _storageBucket,
      );
    }

    final appId = switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        const String.fromEnvironment('FIREBASE_ANDROID_APP_ID'),
      TargetPlatform.iOS => const String.fromEnvironment('FIREBASE_IOS_APP_ID'),
      TargetPlatform.macOS =>
        const String.fromEnvironment('FIREBASE_MACOS_APP_ID'),
      _ => throw UnsupportedError(
          'Firebase sync is supported on Android, iOS, macOS, and web.',
        ),
    };

    return FirebaseOptions(
      apiKey: _apiKey,
      appId: appId,
      messagingSenderId: _messagingSenderId,
      projectId: _projectId,
      storageBucket: _storageBucket,
      iosBundleId: defaultTargetPlatform == TargetPlatform.iOS
          ? const String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID')
          : null,
    );
  }

  static bool get hasRequiredOptions {
    if (!_configured ||
        _apiKey.isEmpty ||
        _projectId.isEmpty ||
        _messagingSenderId.isEmpty) {
      return false;
    }
    if (kIsWeb) {
      return const String.fromEnvironment('FIREBASE_WEB_APP_ID').isNotEmpty &&
          const String.fromEnvironment('FIREBASE_AUTH_DOMAIN').isNotEmpty;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        const String.fromEnvironment('FIREBASE_ANDROID_APP_ID').isNotEmpty,
      TargetPlatform.iOS =>
        const String.fromEnvironment('FIREBASE_IOS_APP_ID').isNotEmpty &&
            const String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID').isNotEmpty,
      TargetPlatform.macOS =>
        const String.fromEnvironment('FIREBASE_MACOS_APP_ID').isNotEmpty,
      _ => false,
    };
  }
}
