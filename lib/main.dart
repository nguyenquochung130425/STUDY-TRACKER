import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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

  const StudyTrackerApp({
    super.key,
    this.firebaseReady = false,
    this.firebaseInitializationError,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<StudyProvider>(
          create: (_) => StudyProvider(),
        ),
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
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3F51B5),
            brightness: Brightness.light,
          ),
          cardTheme: const CardThemeData(
            elevation: 0,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3F51B5),
            brightness: Brightness.dark,
          ),
          cardTheme: const CardThemeData(
            elevation: 0,
          ),
        ),
        themeMode: ThemeMode.system,
        home: const MainNavigationScreen(),
      ),
    );
  }
}
