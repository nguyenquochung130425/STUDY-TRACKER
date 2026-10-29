import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_tracker/core/utils/gpa_helper.dart';
import 'package:study_tracker/models/grade_entry.dart';
import 'package:study_tracker/models/subject.dart';
import 'package:study_tracker/providers/study_provider.dart';

Future<void> waitForProvider(StudyProvider provider) async {
  while (provider.isLoading) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

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

  group('GPA Calculation & Simulator Tests', () {
    test('calculates semester GPA with credit weighting and simulated what-if target', () async {
      SharedPreferences.setMockInitialValues({});
      final studyProvider = StudyProvider();
      await waitForProvider(studyProvider);

      final subject1 = const Subject(
        id: 'sub_math',
        name: 'Toán cao cấp',
        credits: 3,
        colorValue: 0xFF2196F3,
        semester: 'Học kỳ 1 2026-2027',
      );
      final subject2 = const Subject(
        id: 'sub_prog',
        name: 'Lập trình di động',
        credits: 4,
        colorValue: 0xFF4CAF50,
        semester: 'Học kỳ 1 2026-2027',
      );

      await studyProvider.addSubject(subject1);
      await studyProvider.addSubject(subject2);

      // Điểm môn Toán: 8.5 (Hệ 4: 4.0, A)
      await studyProvider.addGrade(
        GradeEntry(
          id: 'g_math',
          subjectId: 'sub_math',
          title: 'Tổng kết',
          score: 8.5,
          maxScore: 10.0,
          weight: 100.0,
          createdAt: DateTime.now(),
        ),
      );

      // Điểm môn Lập trình: 7.5 (Hệ 4: 3.0, B)
      await studyProvider.addGrade(
        GradeEntry(
          id: 'g_prog',
          subjectId: 'sub_prog',
          title: 'Tổng kết',
          score: 7.5,
          maxScore: 10.0,
          weight: 100.0,
          createdAt: DateTime.now(),
        ),
      );

      // Điểm trung bình có trọng số tín chỉ:
      // Tổng điểm hệ 4 = (4.0 * 3) + (3.0 * 4) = 12.0 + 12.0 = 24.0
      // Tổng tín chỉ = 3 + 4 = 7
      // GPA hệ 4 = 24.0 / 7 = 3.4285...
      final avg1 = studyProvider.getSubjectWeightedAverage('sub_math')!;
      final avg2 = studyProvider.getSubjectWeightedAverage('sub_prog')!;
      expect(avg1, 8.5);
      expect(avg2, 7.5);

      final gpa4Math = GpaHelper.score10To4(avg1);
      final gpa4Prog = GpaHelper.score10To4(avg2);
      expect(gpa4Math, 4.0);
      expect(gpa4Prog, 3.0);

      final totalCredits = subject1.credits + subject2.credits;
      final currentGpa4 = ((gpa4Math * subject1.credits) + (gpa4Prog * subject2.credits)) / totalCredits;
      expect((currentGpa4 * 100).round() / 100, 3.43);

      // Giả lập What-If: Cải thiện môn Lập trình lên 8.5 (hệ 4: 4.0)
      const simulatedScoreProg = 8.5;
      final simGpa4Prog = GpaHelper.score10To4(simulatedScoreProg);
      final simulatedGpa4 = ((gpa4Math * subject1.credits) + (simGpa4Prog * subject2.credits)) / totalCredits;
      expect(simulatedGpa4, 4.0);
    });
  });
}
