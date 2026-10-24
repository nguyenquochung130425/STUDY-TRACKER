import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_tracker/models/grade_entry.dart';
import 'package:study_tracker/models/study_session.dart';
import 'package:study_tracker/providers/study_provider.dart';

Future<void> waitForProvider(StudyProvider provider) async {
  while (provider.isLoading) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('calculates weighted subject average on a ten-point scale', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = StudyProvider();
    await waitForProvider(provider);

    await provider.addGrade(
      GradeEntry(
        id: 'grade_midterm',
        subjectId: 'sub_1',
        title: 'Giữa kỳ',
        score: 8,
        maxScore: 10,
        weight: 40,
        createdAt: DateTime(2026, 10, 1),
      ),
    );
    await provider.addGrade(
      GradeEntry(
        id: 'grade_final',
        subjectId: 'sub_1',
        title: 'Cuối kỳ',
        score: 90,
        maxScore: 100,
        weight: 60,
        createdAt: DateTime(2026, 10, 2),
      ),
    );

    expect(provider.getSubjectWeightedAverage('sub_1'), 8.6);
    expect(provider.overallWeightedAverage, 8.6);
  });

  test('persists grades locally and can delete them', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = StudyProvider();
    await waitForProvider(provider);
    final grade = GradeEntry(
      id: 'grade_quiz',
      subjectId: 'sub_2',
      title: 'Bài kiểm tra',
      score: 7.5,
      maxScore: 10,
      weight: 20,
      createdAt: DateTime(2026, 10, 3),
    );
    await provider.addGrade(grade);

    final restoredProvider = StudyProvider();
    await waitForProvider(restoredProvider);
    expect(restoredProvider.grades.single.toJson(), grade.toJson());

    await restoredProvider.deleteGrade(grade.id);
    expect(restoredProvider.grades, isEmpty);
    expect(restoredProvider.getSubjectWeightedAverage('sub_2'), isNull);

    await restoredProvider.mergeCloudData(
      remoteRecords: {
        'subjects': {},
        'sessions': {},
        'tasks': {},
        'grades': {grade.id: grade.toJson()},
      },
      remoteModifiedAt: {
        'grades/${grade.id}': DateTime.fromMillisecondsSinceEpoch(
          0,
          isUtc: true,
        ),
      },
      remoteDeletedRecords: {},
    );
    expect(restoredProvider.grades, isEmpty);
  });

  test('updates grades and retains the original entry date', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = StudyProvider();
    await waitForProvider(provider);
    final createdAt = DateTime(2026, 10, 3);
    final grade = GradeEntry(
      id: 'grade_quiz',
      subjectId: 'sub_2',
      title: 'Bài kiểm tra',
      score: 7.5,
      maxScore: 10,
      weight: 20,
      createdAt: createdAt,
    );

    await provider.addGrade(grade);
    await provider.updateGrade(
      GradeEntry(
        id: grade.id,
        subjectId: grade.subjectId,
        title: 'Bài kiểm tra lần 1',
        score: 8,
        maxScore: grade.maxScore,
        weight: grade.weight,
        createdAt: grade.createdAt,
      ),
    );

    expect(provider.grades.single.title, 'Bài kiểm tra lần 1');
    expect(provider.grades.single.score, 8);
    expect(provider.grades.single.createdAt, createdAt);
    expect(provider.getSubjectWeightedAverage('sub_2'), 8);
  });

  test('excludes future sessions from weekly progress', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = StudyProvider();
    await waitForProvider(provider);
    await provider.addSession(
      StudySession(
        id: 'session_future',
        subjectId: 'sub_1',
        durationSeconds: 3600,
        timestamp: DateTime.now().add(const Duration(hours: 2)),
      ),
    );

    expect(provider.thisWeekSeconds, 0);
    expect(provider.thisWeekSessionsCount, 0);
    expect(provider.getSubjectSecondsThisWeek('sub_1'), 0);
    expect(provider.weeklyMinutes.reduce((a, b) => a + b), 0);
  });
}
