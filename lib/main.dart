import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/widgets/app_lock_wrapper.dart';
import 'providers/auth_provider.dart';
import 'providers/pomodoro_provider.dart';
import 'providers/security_provider.dart';
import 'providers/study_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StudyTrackerApp());
}

class StudyTrackerApp extends StatelessWidget {
  const StudyTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider<SecurityProvider>(
          create: (_) => SecurityProvider(),
        ),
        ChangeNotifierProvider<StudyProvider>(
          create: (_) => StudyProvider(),
        ),
        ChangeNotifierProxyProvider<StudyProvider, PomodoroProvider>(
          create: (_) => PomodoroProvider(),
          update: (_, studyProvider, pomodoroProvider) {
            return (pomodoroProvider ?? PomodoroProvider())
              ..updateStudyProvider(studyProvider);
          },
        ),
      ],
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, themeProvider, authProvider, _) {
          return MaterialApp(
            title: 'Study Tracker',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: AppLockWrapper(
              child: authProvider.isAuthenticated
                  ? const MainNavigationScreen()
                  : const LoginScreen(),
            ),
          );
        },
      ),
    );
  }
}
