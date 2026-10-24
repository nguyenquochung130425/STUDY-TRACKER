import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_tracker/features/analytics/study_analytics_service.dart';
import 'package:study_tracker/features/cloud_sync/cloud_sync_service.dart';
import 'package:study_tracker/models/grade_entry.dart';
import 'package:study_tracker/models/study_session.dart';
import 'package:study_tracker/models/subject.dart';

void main() {
  group('StudyAnalyticsService', () {
    const analytics = StudyAnalyticsService();

    test('summarizes current study data and weighted grade average', () {
      final now = DateTime(2026, 10, 24, 15);
      final today = StudySession(
        id: 'today',
        subjectId: 'math',
        durationSeconds: 3600,
        timestamp: now.subtract(const Duration(hours: 1)),
      );
      final yesterday = StudySession(
        id: 'yesterday',
        subjectId: 'math',
        durationSeconds: 1800,
        timestamp: now.subtract(const Duration(days: 1)),
      );
      final future = StudySession(
        id: 'future',
        subjectId: 'math',
        durationSeconds: 7200,
        timestamp: now.add(const Duration(hours: 1)),
      );
      final math = const Subject(
        id: 'math',
        name: 'Toán',
        colorValue: 0xFF2196F3,
        weeklyTargetHours: 5,
      );
      final grades = [
        GradeEntry(
          id: 'quiz',
          subjectId: 'math',
          title: 'Quiz',
          score: 8,
          maxScore: 10,
          weight: 25,
          createdAt: now,
        ),
        GradeEntry(
          id: 'exam',
          subjectId: 'math',
          title: 'Exam',
          score: 9,
          maxScore: 10,
          weight: 75,
          createdAt: now,
        ),
      ];

      final summary = analytics.summarize(
        sessions: [today, yesterday, future],
        grades: grades,
        subjects: [math],
        now: now,
      );

      expect(summary.totalMinutesToday, 60);
      expect(summary.totalMinutesThisWeek, 90);
      expect(summary.currentStreak, 2);
      expect(summary.averageGrade, 8.75);
      expect(
        analytics.subjectProgress(
          [math],
          [today, yesterday, future],
          now: now,
        )['math'],
        closeTo(30, 0.001),
      );
    });

    test('returns zero streak after a missed full day', () {
      final now = DateTime(2026, 10, 24, 15);
      final session = StudySession(
        id: 'old',
        subjectId: 'math',
        durationSeconds: 1800,
        timestamp: now.subtract(const Duration(days: 2)),
      );

      expect(analytics.calculateCurrentStreak([session], now: now), 0);
    });
  });

  group('CloudSyncService', () {
    test('writes when local data is newer or differs', () {
      final updatedAt = DateTime.utc(2026, 10, 24);

      expect(
        CloudSyncService.shouldWriteLocalRecord(
          documentExists: true,
          currentBody: {'name': 'Remote'},
          localBody: {'name': 'Local'},
          localModifiedAt: updatedAt,
          remoteUpdatedAt: Timestamp.fromDate(updatedAt),
        ),
        isTrue,
      );
      expect(
        CloudSyncService.shouldWriteLocalRecord(
          documentExists: true,
          currentBody: {'name': 'Same'},
          localBody: {'name': 'Same'},
          localModifiedAt: updatedAt.subtract(const Duration(seconds: 1)),
          remoteUpdatedAt: Timestamp.fromDate(updatedAt),
        ),
        isFalse,
      );
    });
  });
}
