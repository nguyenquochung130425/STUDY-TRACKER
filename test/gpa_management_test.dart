import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_tracker/core/utils/gpa_helper.dart';
import 'package:study_tracker/models/grade_entry.dart';
import 'package:study_tracker/models/subject.dart';
import 'package:study_tracker/providers/schedule_provider.dart';
import 'package:study_tracker/providers/study_provider.dart';
import 'package:study_tracker/screens/subject_list_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GpaHelper Unit Tests', () {
    test('converts score 10 to score 4 accurately according to VN university credit standard', () {
      expect(GpaHelper.score10To4(10.0), 4.0);
      expect(GpaHelper.score10To4(8.5), 4.0);
      expect(GpaHelper.score10To4(8.2), 3.5);
      expect(GpaHelper.score10To4(7.5), 3.0);
      expect(GpaHelper.score10To4(6.8), 2.5);
      expect(GpaHelper.score10To4(6.0), 2.0);
      expect(GpaHelper.score10To4(5.2), 1.5);
      expect(GpaHelper.score10To4(4.5), 1.0);
      expect(GpaHelper.score10To4(3.5), 0.0);
    });

    test('converts score 10 to letter grade accurately', () {
      expect(GpaHelper.scoreToLetter(9.5), 'A+');
      expect(GpaHelper.scoreToLetter(8.8), 'A');
      expect(GpaHelper.scoreToLetter(8.2), 'B+');
      expect(GpaHelper.scoreToLetter(7.4), 'B');
      expect(GpaHelper.scoreToLetter(6.7), 'C+');
      expect(GpaHelper.scoreToLetter(5.8), 'C');
      expect(GpaHelper.scoreToLetter(5.2), 'D+');
      expect(GpaHelper.scoreToLetter(4.5), 'D');
      expect(GpaHelper.scoreToLetter(3.0), 'F');
    });

    test('classifies academic performance from GPA', () {
      expect(GpaHelper.getGpaClassification(3.8), 'Xuất sắc');
      expect(GpaHelper.getGpaClassification(3.45), 'Giỏi');
      expect(GpaHelper.getGpaClassification(2.8), 'Khá');
      expect(GpaHelper.getGpaClassification(2.2), 'Trung bình');
      expect(GpaHelper.getGpaClassification(1.5), 'Cần cố gắng');
    });
  });

  group('SubjectListScreen GPA Integration Tests', () {
    testWidgets('displays GPA Stats Chip in top summary bar and grade badge in subject card', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final studyProvider = StudyProvider();
      while (studyProvider.isLoading) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }

      // Add a test subject with 3 credits
      final subject = const Subject(
        id: 'sub_mobile',
        name: 'Lập trình Trên thiết bị di động',
        code: '2323',
        credits: 3,
        lecturer: 'nguyeds',
        semester: 'Học kỳ 1 2026-2027',
        colorValue: 0xFF4F46E5,
        weeklyTargetHours: 5.0,
      );
      await studyProvider.addSubject(subject);

      // Add grade 8.5 for this subject (Hệ 10: 8.5 -> Hệ 4: 4.0, Điểm chữ: A)
      final grade = GradeEntry(
        id: 'grade_mob_1',
        subjectId: 'sub_mobile',
        title: 'Điểm tổng kết',
        score: 8.5,
        maxScore: 10.0,
        weight: 100.0,
        createdAt: DateTime.now(),
      );
      await studyProvider.addGrade(grade);

      final scheduleProvider = ScheduleProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<StudyProvider>.value(value: studyProvider),
            ChangeNotifierProvider<ScheduleProvider>.value(value: scheduleProvider),
          ],
          child: const MaterialApp(
            home: SubjectListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify GPA Stats Chip is displayed in top summary bar
      expect(find.textContaining('🎯 GPA'), findsWidgets);
      expect(find.textContaining('4.00'), findsWidgets);

      // 2. Verify Subject Card displays grade
      expect(find.text('Lập trình Trên thiết bị di động'), findsOneWidget);
      expect(find.text('3 tín chỉ'), findsWidgets);
      expect(find.textContaining('Điểm: 4.0'), findsOneWidget);
      expect(find.text('A'), findsWidgets);

      // 3. Verify GPA Calculator button in AppBar opens sheet
      final calcButton = find.byIcon(Icons.calculate_outlined);
      expect(calcButton, findsOneWidget);
      await tester.tap(calcButton);
      await tester.pumpAndSettle();

      // Verify GPA Sheet content
      expect(find.text('Bảng Điểm & Tính GPA'), findsOneWidget);
      expect(find.text('Thang điểm 4.0'), findsOneWidget);
      expect(find.text('Bảng Điểm Môn Học'), findsOneWidget);
      expect(find.text('Mô Phỏng GPA (What-If)'), findsOneWidget);

      // Switch to What-If simulation tab
      await tester.tap(find.text('Mô Phỏng GPA (What-If)'));
      await tester.pumpAndSettle();

      expect(find.text('GPA Dự Kiến Sau Mô Phỏng:'), findsOneWidget);
      expect(find.textContaining('Kéo slider để thử nghiệm'), findsOneWidget);
    });
  });
}
