import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_tracker/providers/pomodoro_provider.dart';
import 'package:study_tracker/providers/study_provider.dart';
import 'package:study_tracker/widgets/subject_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('subject card shows elapsed focus time before the session ends', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final study = StudyProvider();
    await study.ready;
    final pomodoro = PomodoroProvider()..updateStudyProvider(study);
    addTearDown(study.dispose);
    addTearDown(pomodoro.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<StudyProvider>.value(value: study),
          ChangeNotifierProvider<PomodoroProvider>.value(value: pomodoro),
        ],
        child: MaterialApp(
          home: Scaffold(body: SubjectCard(subject: study.subjects.first)),
        ),
      ),
    );

    pomodoro.start();
    await tester.pump(const Duration(minutes: 1));
    pomodoro.pause();
    await tester.pump();

    expect(find.text('Hôm nay: 1 phút'), findsOneWidget);
  });
}
