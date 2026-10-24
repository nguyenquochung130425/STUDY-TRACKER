import 'package:intl/intl.dart';

import '../../models/grade_entry.dart';
import '../../models/study_session.dart';
import '../../models/subject.dart';

class StudyAnalyticsSummary {
  final double totalMinutesToday;
  final double totalMinutesThisWeek;
  final int currentStreak;
  final double averageGrade;

  const StudyAnalyticsSummary({
    required this.totalMinutesToday,
    required this.totalMinutesThisWeek,
    required this.currentStreak,
    required this.averageGrade,
  });
}

class StudyAnalyticsService {
  const StudyAnalyticsService();

  StudyAnalyticsSummary summarize({
    required List<StudySession> sessions,
    required List<GradeEntry> grades,
    required List<Subject> subjects,
    DateTime? now,
  }) {
    final referenceTime = now ?? DateTime.now();
    final todayStart = DateTime(
      referenceTime.year,
      referenceTime.month,
      referenceTime.day,
    );
    final weekStart = todayStart.subtract(
      Duration(days: todayStart.weekday - 1),
    );

    final totalTodayMinutes = sessions
        .where(
          (session) =>
              !session.timestamp.isBefore(todayStart) &&
              session.timestamp.isBefore(
                todayStart.add(const Duration(days: 1)),
              ) &&
              !session.timestamp.isAfter(referenceTime),
        )
        .fold<double>(
          0,
          (sum, session) => sum + (session.durationSeconds / 60),
        );

    final totalWeekMinutes = sessions
        .where(
          (session) =>
              !session.timestamp.isBefore(weekStart) &&
              session.timestamp.isBefore(
                weekStart.add(const Duration(days: 7)),
              ) &&
              !session.timestamp.isAfter(referenceTime),
        )
        .fold<double>(
          0,
          (sum, session) => sum + (session.durationSeconds / 60),
        );

    final streak = calculateCurrentStreak(sessions, now: referenceTime);

    final subjectAverages = <double>[];
    for (final subject in subjects) {
      final subjectGrades = grades
          .where((entry) => entry.subjectId == subject.id && entry.weight > 0)
          .where((entry) => entry.maxScore > 0)
          .toList();
      final totalWeight = subjectGrades.fold<double>(
        0,
        (sum, entry) => sum + entry.weight,
      );
      if (totalWeight == 0) continue;
      final weightedScore = subjectGrades.fold<double>(
        0,
        (sum, entry) => sum + entry.normalizedScore * entry.weight,
      );
      subjectAverages.add(weightedScore / totalWeight);
    }
    final averageGrade = subjectAverages.isEmpty
        ? 0.0
        : subjectAverages.reduce((sum, average) => sum + average) /
              subjectAverages.length;

    return StudyAnalyticsSummary(
      totalMinutesToday: totalTodayMinutes,
      totalMinutesThisWeek: totalWeekMinutes,
      currentStreak: streak,
      averageGrade: averageGrade,
    );
  }

  int calculateCurrentStreak(List<StudySession> sessions, {DateTime? now}) {
    if (sessions.isEmpty) {
      return 0;
    }

    final dates =
        sessions
            .map(
              (session) => DateTime(
                session.timestamp.year,
                session.timestamp.month,
                session.timestamp.day,
              ),
            )
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    if (dates.isEmpty) {
      return 0;
    }

    var streak = 0;
    final referenceTime = now ?? DateTime.now();
    var cursor = DateTime(
      referenceTime.year,
      referenceTime.month,
      referenceTime.day,
    );
    final normalized = dates.toSet();
    if (!normalized.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    while (normalized.contains(
      DateTime(cursor.year, cursor.month, cursor.day),
    )) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  Map<String, double> subjectProgress(
    List<Subject> subjects,
    List<StudySession> sessions, {
    DateTime? now,
  }) {
    final result = <String, double>{};
    final grouped = <String, double>{};
    final referenceTime = now ?? DateTime.now();
    final todayStart = DateTime(
      referenceTime.year,
      referenceTime.month,
      referenceTime.day,
    );
    final weekStart = todayStart.subtract(
      Duration(days: todayStart.weekday - 1),
    );
    final weekEnd = weekStart.add(const Duration(days: 7));

    for (final session in sessions) {
      if (session.timestamp.isBefore(weekStart) ||
          !session.timestamp.isBefore(weekEnd) ||
          session.timestamp.isAfter(referenceTime)) {
        continue;
      }
      final key = session.subjectId;
      grouped[key] = (grouped[key] ?? 0) + (session.durationSeconds / 60);
    }

    for (final subject in subjects) {
      final minutes = grouped[subject.id] ?? 0.0;
      final target = subject.weeklyTargetHours * 60;
      final progress = target <= 0
          ? 0.0
          : ((minutes / target) * 100).clamp(0.0, 100.0);
      result[subject.id] = progress;
    }

    return result;
  }

  String formatMinutes(double minutes) {
    final totalMinutes = minutes.round();
    final hours = totalMinutes ~/ 60;
    final rem = totalMinutes % 60;
    return '${hours}h ${rem}m';
  }

  String formatDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);
}
