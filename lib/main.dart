import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/pomodoro_provider.dart';
import 'providers/study_provider.dart';
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
