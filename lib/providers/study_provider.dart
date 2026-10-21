import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/grade_entry.dart';
import '../models/study_session.dart';
import '../models/study_task.dart';
import '../models/subject.dart';

class StudyProvider extends ChangeNotifier {
  static const String _subjectsKey = 'study_tracker_subjects';
  static const String _sessionsKey = 'study_tracker_sessions';
  static const String _tasksKey = 'study_tracker_tasks';
  static const String _gradesKey = 'study_tracker_grades';
  static const String _modifiedAtKey = 'study_tracker_sync_modified_at';
  static const String _deletedRecordsKey = 'study_tracker_sync_deleted_records';

  List<Subject> _subjects = [];
  List<StudySession> _sessions = [];
  List<StudyTask> _tasks = [];
  List<GradeEntry> _grades = [];
  final Map<String, DateTime> _modifiedAt = {};
  final Map<String, DateTime> _deletedRecords = {};
  final Completer<void> _readyCompleter = Completer<void>();
  VoidCallback? _onLocalChange;
  bool _isLoading = true;

  StudyProvider() {
    _loadFromPreferences();
  }

  bool get isLoading => _isLoading;
  Future<void> get ready => _readyCompleter.future;
  List<Subject> get subjects => List.unmodifiable(_subjects);
  List<StudySession> get sessions => List.unmodifiable(_sessions);
  List<StudyTask> get tasks => List.unmodifiable(_tasks);
  List<GradeEntry> get grades => List.unmodifiable(_grades);
  Map<String, DateTime> get deletedRecords => Map.unmodifiable(_deletedRecords);

  void setCloudSyncCallback(VoidCallback? callback) {
    _onLocalChange = callback;
  }

  DateTime? modifiedAtFor(String collection, String id) =>
      _modifiedAt['$collection/$id'];

  Map<String, Map<String, Map<String, dynamic>>> exportCloudData() => {
    'subjects': {for (final item in _subjects) item.id: item.toJson()},
    'sessions': {for (final item in _sessions) item.id: item.toJson()},
    'tasks': {for (final item in _tasks) item.id: item.toJson()},
    'grades': {for (final item in _grades) item.id: item.toJson()},
  };

  Subject? getSubjectById(String id) {
    try {
      return _subjects.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final modifiedAtRaw = prefs.getString(_modifiedAtKey);
    if (modifiedAtRaw != null) {
      final decoded = jsonDecode(modifiedAtRaw) as Map<String, dynamic>;
      _modifiedAt.addAll(
        decoded.map(
          (key, value) => MapEntry(key, DateTime.parse(value as String)),
        ),
      );
    }
    final deletedRecordsRaw = prefs.getString(_deletedRecordsKey);
    if (deletedRecordsRaw != null) {
      final decoded = jsonDecode(deletedRecordsRaw) as Map<String, dynamic>;
      _deletedRecords.addAll(
        decoded.map(
          (key, value) => MapEntry(key, DateTime.parse(value as String)),
        ),
      );
    }

    final subjectsRaw = prefs.getString(_subjectsKey);
    if (subjectsRaw != null) {
      final List decoded = jsonDecode(subjectsRaw);
      _subjects = decoded.map((item) => Subject.fromJson(item)).toList();
    } else {
      // Dữ liệu môn học mặc định ban đầu
      _subjects = [
        const Subject(
          id: 'sub_1',
          name: 'Toán học',
          colorValue: 0xFF2196F3,
          iconCodePoint: 0xe158, // calculate
          weeklyTargetHours: 6.0,
        ),
        const Subject(
          id: 'sub_2',
          name: 'Lập trình',
          colorValue: 0xFF4CAF50,
          iconCodePoint: 0xe197, // code
          weeklyTargetHours: 10.0,
        ),
        const Subject(
          id: 'sub_3',
          name: 'Tiếng Anh',
          colorValue: 0xFFE91E63,
          iconCodePoint: 0xe357, // language
          weeklyTargetHours: 5.0,
        ),
        const Subject(
          id: 'sub_4',
          name: 'Khoa học',
          colorValue: 0xFFFF9800,
          iconCodePoint: 0xe556, // science
          weeklyTargetHours: 4.0,
        ),
      ];
      await _saveSubjects();
    }

    final sessionsRaw = prefs.getString(_sessionsKey);
    if (sessionsRaw != null) {
      final List decoded = jsonDecode(sessionsRaw);
      _sessions = decoded.map((item) => StudySession.fromJson(item)).toList();
    }

    final tasksRaw = prefs.getString(_tasksKey);
    if (tasksRaw != null) {
      final List decoded = jsonDecode(tasksRaw);
      _tasks = decoded.map((item) => StudyTask.fromJson(item)).toList();
    } else {
      _tasks = [
        StudyTask(
          id: 'task_1',
          title: 'Ôn tập 20 từ vựng tiếng Anh chủ đề Công nghệ',
          subjectId: 'sub_3',
          dueDate: DateTime.now().add(const Duration(days: 1)),
          isCompleted: false,
        ),
        StudyTask(
          id: 'task_2',
          title: 'Hoàn thành bài tập Thuật toán sắp xếp',
          subjectId: 'sub_2',
          dueDate: DateTime.now().add(const Duration(days: 2)),
          isCompleted: false,
        ),
      ];
      await _saveTasks();
    }

    final gradesRaw = prefs.getString(_gradesKey);
    if (gradesRaw != null) {
      final List decoded = jsonDecode(gradesRaw);
      _grades = decoded.map((item) => GradeEntry.fromJson(item)).toList();
    }

    _isLoading = false;
    notifyListeners();
    _readyCompleter.complete();
  }

  Future<void> _saveSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_subjects.map((s) => s.toJson()).toList());
    await prefs.setString(_subjectsKey, data);
  }

  Future<void> _saveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_sessions.map((s) => s.toJson()).toList());
    await prefs.setString(_sessionsKey, data);
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_tasks.map((t) => t.toJson()).toList());
    await prefs.setString(_tasksKey, data);
  }

  Future<void> _saveGrades() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_grades.map((grade) => grade.toJson()).toList());
    await prefs.setString(_gradesKey, data);
  }

  Future<void> _saveSyncMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _modifiedAtKey,
      jsonEncode(
        _modifiedAt.map((key, value) => MapEntry(key, value.toIso8601String())),
      ),
    );
    await prefs.setString(
      _deletedRecordsKey,
      jsonEncode(
        _deletedRecords.map(
          (key, value) => MapEntry(key, value.toIso8601String()),
        ),
      ),
    );
  }

  Future<void> _persistAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _subjectsKey,
      jsonEncode(_subjects.map((item) => item.toJson()).toList()),
    );
    await prefs.setString(
      _sessionsKey,
      jsonEncode(_sessions.map((item) => item.toJson()).toList()),
    );
    await prefs.setString(
      _tasksKey,
      jsonEncode(_tasks.map((item) => item.toJson()).toList()),
    );
    await prefs.setString(
      _gradesKey,
      jsonEncode(_grades.map((item) => item.toJson()).toList()),
    );
    await prefs.setString(
      _modifiedAtKey,
      jsonEncode(
        _modifiedAt.map((key, value) => MapEntry(key, value.toIso8601String())),
      ),
    );
    await prefs.setString(
      _deletedRecordsKey,
      jsonEncode(
        _deletedRecords.map(
          (key, value) => MapEntry(key, value.toIso8601String()),
        ),
      ),
    );
  }

  Future<void> mergeCloudData({
    required Map<String, Map<String, Map<String, dynamic>>> remoteRecords,
    required Map<String, DateTime> remoteModifiedAt,
    required Map<String, DateTime> remoteDeletedRecords,
  }) async {
    final merged = exportCloudData();
    final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final collections = <String>['subjects', 'sessions', 'tasks', 'grades'];

    for (final entry in remoteDeletedRecords.entries) {
      final current = _deletedRecords[entry.key];
      if (current == null || entry.value.isAfter(current)) {
        _deletedRecords[entry.key] = entry.value;
      }
    }

    for (final collection in collections) {
      final records = merged[collection]!;
      for (final record in remoteRecords[collection]!.entries) {
        final key = '$collection/${record.key}';
        final localModified = _modifiedAt[key] ?? epoch;
        final remoteModified = remoteModifiedAt[key] ?? epoch;
        final deletedAt = _deletedRecords[key];

        if (deletedAt != null && !remoteModified.isAfter(deletedAt)) {
          continue;
        }
        if (!records.containsKey(record.key) ||
            remoteModified.isAfter(localModified)) {
          records[record.key] = record.value;
          _modifiedAt[key] = remoteModified;
          if (deletedAt != null && remoteModified.isAfter(deletedAt)) {
            _deletedRecords.remove(key);
          }
        }
      }
    }

    for (final entry in _deletedRecords.entries.toList()) {
      final separator = entry.key.indexOf('/');
      if (separator < 0) continue;
      final collection = entry.key.substring(0, separator);
      final id = entry.key.substring(separator + 1);
      final record = merged[collection]?[id];
      final modifiedAt = _modifiedAt[entry.key] ?? epoch;
      final remoteTime = remoteModifiedAt[entry.key] ?? epoch;
      final effectiveModifiedAt = remoteTime.isAfter(modifiedAt)
          ? remoteTime
          : modifiedAt;

      if (record == null || !effectiveModifiedAt.isAfter(entry.value)) {
        merged[collection]?.remove(id);
        _modifiedAt.remove(entry.key);
      } else {
        _deletedRecords.remove(entry.key);
      }
    }

    _subjects = merged['subjects']!.values.map(Subject.fromJson).toList();
    _sessions = merged['sessions']!.values.map(StudySession.fromJson).toList();
    _tasks = merged['tasks']!.values.map(StudyTask.fromJson).toList();
    _grades = merged['grades']!.values.map(GradeEntry.fromJson).toList();
    await _persistAll();
    notifyListeners();
  }

  void _notifyLocalChange() {
    notifyListeners();
    _onLocalChange?.call();
  }

  Future<void> _markModified(String collection, String id) async {
    _modifiedAt['$collection/$id'] = DateTime.now().toUtc();
    _deletedRecords.remove('$collection/$id');
    await _saveSyncMetadata();
  }

  Future<void> _markDeleted(String collection, String id) async {
    _deletedRecords['$collection/$id'] = DateTime.now().toUtc();
    _modifiedAt.remove('$collection/$id');
    await _saveSyncMetadata();
  }

  // --- SUBJECTS ACTIONS ---
  Future<void> addSubject(Subject subject) async {
    await _markModified('subjects', subject.id);
    _subjects.add(subject);
    await _saveSubjects();
    _notifyLocalChange();
  }

  Future<void> updateSubject(Subject updated) async {
    final index = _subjects.indexWhere((s) => s.id == updated.id);
    if (index != -1) {
      await _markModified('subjects', updated.id);
      _subjects[index] = updated;
      await _saveSubjects();
      _notifyLocalChange();
    }
  }

  Future<void> deleteSubject(String id) async {
    if (_subjects.any((subject) => subject.id == id)) {
      await _markDeleted('subjects', id);
    }
    _subjects.removeWhere((s) => s.id == id);
    await _saveSubjects();
    _notifyLocalChange();
  }

  // --- SESSIONS ACTIONS ---
  Future<void> addSession(StudySession session) async {
    await _markModified('sessions', session.id);
    _sessions.insert(0, session);
    await _saveSessions();
    _notifyLocalChange();
  }

  Future<void> addGrade(GradeEntry grade) async {
    await _markModified('grades', grade.id);
    _grades.insert(0, grade);
    await _saveGrades();
    _notifyLocalChange();
  }

  Future<void> updateGrade(GradeEntry updated) async {
    final index = _grades.indexWhere((grade) => grade.id == updated.id);
    if (index != -1) {
      await _markModified('grades', updated.id);
      _grades[index] = updated;
      await _saveGrades();
      _notifyLocalChange();
    }
  }

  Future<void> deleteGrade(String id) async {
    if (_grades.any((grade) => grade.id == id)) {
      await _markDeleted('grades', id);
    }
    _grades.removeWhere((grade) => grade.id == id);
    await _saveGrades();
    _notifyLocalChange();
  }

  double? getSubjectWeightedAverage(String subjectId) {
    final subjectGrades = _grades
        .where((grade) => grade.subjectId == subjectId)
        .toList();
    if (subjectGrades.isEmpty) return null;

    final totalWeight = subjectGrades.fold<double>(
      0,
      (sum, grade) => sum + grade.weight,
    );
    if (totalWeight <= 0) return null;

    final weightedTotal = subjectGrades.fold<double>(
      0,
      (sum, grade) => sum + grade.normalizedScore * grade.weight,
    );
    return weightedTotal / totalWeight;
  }

  double? get overallWeightedAverage {
    final subjectAverages = _subjects
        .map((subject) => getSubjectWeightedAverage(subject.id))
        .whereType<double>()
        .toList();
    if (subjectAverages.isEmpty) return null;

    return subjectAverages.reduce((sum, average) => sum + average) /
        subjectAverages.length;
  }

  // --- TASKS ACTIONS ---
  Future<void> addTask(StudyTask task) async {
    await _markModified('tasks', task.id);
    _tasks.insert(0, task);
    await _saveTasks();
    _notifyLocalChange();
  }

  Future<void> toggleTaskCompletion(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final task = _tasks[index];
      await _markModified('tasks', id);
      _tasks[index] = task.copyWith(isCompleted: !task.isCompleted);
      await _saveTasks();
      _notifyLocalChange();
    }
  }

  Future<void> deleteTask(String id) async {
    if (_tasks.any((task) => task.id == id)) {
      await _markDeleted('tasks', id);
    }
    _tasks.removeWhere((t) => t.id == id);
    await _saveTasks();
    _notifyLocalChange();
  }

  // --- ANALYTICS GETTERS ---
  int get todaySeconds {
    final now = DateTime.now();
    return _sessions
        .where(
          (s) =>
              s.timestamp.year == now.year &&
              s.timestamp.month == now.month &&
              s.timestamp.day == now.day,
        )
        .fold<int>(0, (sum, s) => sum + s.durationSeconds);
  }

  int get todaySessionsCount {
    final now = DateTime.now();
    return _sessions
        .where(
          (s) =>
              s.timestamp.year == now.year &&
              s.timestamp.month == now.month &&
              s.timestamp.day == now.day,
        )
        .length;
  }

  int get thisWeekSeconds {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final beginning = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    final endOfWeek = beginning.add(const Duration(days: 7));

    return _sessions
        .where(
          (s) =>
              !s.timestamp.isBefore(beginning) &&
              s.timestamp.isBefore(endOfWeek) &&
              !s.timestamp.isAfter(now),
        )
        .fold<int>(0, (sum, s) => sum + s.durationSeconds);
  }

  int get thisWeekSessionsCount {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final beginning = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    final endOfWeek = beginning.add(const Duration(days: 7));

    return _sessions
        .where(
          (s) =>
              !s.timestamp.isBefore(beginning) &&
              s.timestamp.isBefore(endOfWeek) &&
              !s.timestamp.isAfter(now),
        )
        .length;
  }

  int getSubjectSecondsToday(String subjectId) {
    final now = DateTime.now();
    return _sessions
        .where(
          (s) =>
              s.subjectId == subjectId &&
              s.timestamp.year == now.year &&
              s.timestamp.month == now.month &&
              s.timestamp.day == now.day,
        )
        .fold<int>(0, (sum, s) => sum + s.durationSeconds);
  }

  int getSubjectSecondsThisWeek(String subjectId) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final beginning = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    final endOfWeek = beginning.add(const Duration(days: 7));

    return _sessions
        .where(
          (s) =>
              s.subjectId == subjectId &&
              !s.timestamp.isBefore(beginning) &&
              s.timestamp.isBefore(endOfWeek) &&
              !s.timestamp.isAfter(now),
        )
        .fold<int>(0, (sum, s) => sum + s.durationSeconds);
  }

  int get currentStreakDays {
    if (_sessions.isEmpty) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final studyDates = _sessions
        .map(
          (s) => DateTime(s.timestamp.year, s.timestamp.month, s.timestamp.day),
        )
        .toSet();

    int streak = 0;
    DateTime checkDate = today;

    // Nếu hôm nay chưa học, kiểm tra bắt đầu từ hôm qua
    if (!studyDates.contains(checkDate)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
      if (!studyDates.contains(checkDate)) {
        return 0;
      }
    }

    while (studyDates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  /// Trả về số phút học trong từng ngày từ Thứ 2 đến Chủ nhật của tuần hiện tại (7 giá trị)
  List<double> get weeklyMinutes {
    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    final List<double> result = List.filled(7, 0.0);

    for (final session in _sessions) {
      final sessionDate = DateTime(
        session.timestamp.year,
        session.timestamp.month,
        session.timestamp.day,
      );
      final diffDays = sessionDate.difference(monday).inDays;
      if (diffDays >= 0 && diffDays < 7 && !session.timestamp.isAfter(now)) {
        result[diffDays] += session.durationSeconds / 60.0;
      }
    }

    return result;
  }
}
