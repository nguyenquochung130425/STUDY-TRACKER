import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/app_lock/app_lock_gate.dart';
import 'features/app_lock/app_lock_provider.dart';
import 'features/app_lock/app_lock_storage.dart';
import 'providers/cloud_sync_provider.dart';
import 'providers/pomodoro_provider.dart';
import 'providers/study_provider.dart';
import 'services/firebase_configuration.dart';
import 'screens/main_navigation_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseReady = false;
  String? firebaseInitializationError;
  if (FirebaseConfiguration.isConfigured) {
    if (!FirebaseConfiguration.hasRequiredOptions) {
      firebaseInitializationError =
          'Thiếu Firebase options cho nền tảng đang chạy. Hãy kiểm tra '
          'các dart-define trong README.';
    } else {
      try {
        await Firebase.initializeApp(
          options: FirebaseConfiguration.currentPlatform,
        );
        firebaseReady = true;
      } on FirebaseException catch (error) {
        firebaseInitializationError =
            'Không thể khởi tạo Firebase (${error.code}): '
            '${error.message ?? 'không có chi tiết'}';
      } on PlatformException catch (error) {
        firebaseInitializationError =
            'Không thể khởi tạo Firebase: ${error.message ?? error.code}';
      }
    }
  }

  runApp(
    StudyTrackerApp(
      firebaseReady: firebaseReady,
      firebaseInitializationError: firebaseInitializationError,
    ),
  );
}

class StudyTrackerApp extends StatelessWidget {
  final bool firebaseReady;
  final String? firebaseInitializationError;
  final AppLockStorage? appLockStorage;

  const StudyTrackerApp({
    super.key,
    this.firebaseReady = false,
    this.firebaseInitializationError,
    this.appLockStorage,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppLockProvider>(
          create: (_) => AppLockProvider(storage: appLockStorage),
        ),
        ChangeNotifierProvider<StudyProvider>(create: (_) => StudyProvider()),
        ChangeNotifierProvider<CloudSyncProvider>(
          create: (context) => CloudSyncProvider(
            studyProvider: context.read<StudyProvider>(),
            firebaseReady: firebaseReady,
            initializationError: firebaseInitializationError,
          ),
        ),
        ChangeNotifierProxyProvider<StudyProvider, PomodoroProvider>(
          create: (_) => PomodoroProvider(),
          update: (_, studyProvider, pomodoroProvider) {
            return (pomodoroProvider ?? PomodoroProvider())
              ..updateStudyProvider(studyProvider);
          },
        ),
      ],
      child: MaterialApp(
        title: 'Study Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        builder: (context, child) =>
            AppLockGate(child: child ?? const SizedBox.shrink()),
        home: const MainNavigationScreen(),
      ),
    );
  }
}
