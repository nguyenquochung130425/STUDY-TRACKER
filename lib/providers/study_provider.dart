import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/study_session.dart';
import '../models/study_task.dart';
import '../models/subject.dart';

class StudyProvider extends ChangeNotifier {
  static const String _subjectsKey = 'study_tracker_subjects';
  static const String _sessionsKey = 'study_tracker_sessions';
  static const String _tasksKey = 'study_tracker_tasks';

  List<Subject> _subjects = [];
  List<StudySession> _sessions = [];
  List<StudyTask> _tasks = [];
  bool _isLoading = true;

  StudyProvider() {
    _loadFromPreferences();
  }

  bool get isLoading => _isLoading;
  List<Subject> get subjects => List.unmodifiable(_subjects);
  List<StudySession> get sessions => List.unmodifiable(_sessions);
  List<StudyTask> get tasks => List.unmodifiable(_tasks);

  Subject? getSubjectById(String id) {
    try {
      return _subjects.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();

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

    _isLoading = false;
    notifyListeners();
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

  // --- SUBJECTS ACTIONS ---
  Future<void> addSubject(Subject subject) async {
    _subjects.add(subject);
    await _saveSubjects();
    notifyListeners();
  }

  Future<void> updateSubject(Subject updated) async {
    final index = _subjects.indexWhere((s) => s.id == updated.id);
    if (index != -1) {
      _subjects[index] = updated;
      await _saveSubjects();
      notifyListeners();
    }
  }

  Future<void> deleteSubject(String id) async {
    _subjects.removeWhere((s) => s.id == id);
    await _saveSubjects();
    notifyListeners();
  }

  // --- SESSIONS ACTIONS ---
  Future<void> addSession(StudySession session) async {
    _sessions.insert(0, session);
    await _saveSessions();
    notifyListeners();
  }

  // --- TASKS ACTIONS ---
  Future<void> addTask(StudyTask task) async {
    _tasks.insert(0, task);
    await _saveTasks();
    notifyListeners();
  }

  Future<void> toggleTaskCompletion(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final task = _tasks[index];
      _tasks[index] = task.copyWith(isCompleted: !task.isCompleted);
      await _saveTasks();
      notifyListeners();
    }
  }

  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    await _saveTasks();
    notifyListeners();
  }

  // --- ANALYTICS GETTERS ---
  int get todaySeconds {
    final now = DateTime.now();
    return _sessions
        .where((s) =>
            s.timestamp.year == now.year &&
            s.timestamp.month == now.month &&
            s.timestamp.day == now.day)
        .fold<int>(0, (sum, s) => sum + s.durationSeconds);
  }

  int get todaySessionsCount {
    final now = DateTime.now();
    return _sessions
        .where((s) =>
            s.timestamp.year == now.year &&
            s.timestamp.month == now.month &&
            s.timestamp.day == now.day)
        .length;
  }

  int get thisWeekSeconds {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final beginning = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    return _sessions
        .where((s) => s.timestamp.isAfter(beginning))
        .fold<int>(0, (sum, s) => sum + s.durationSeconds);
  }

  int getSubjectSecondsToday(String subjectId) {
    final now = DateTime.now();
    return _sessions
        .where((s) =>
            s.subjectId == subjectId &&
            s.timestamp.year == now.year &&
            s.timestamp.month == now.month &&
            s.timestamp.day == now.day)
        .fold<int>(0, (sum, s) => sum + s.durationSeconds);
  }

  int getSubjectSecondsThisWeek(String subjectId) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final beginning = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    return _sessions
        .where((s) => s.subjectId == subjectId && s.timestamp.isAfter(beginning))
        .fold<int>(0, (sum, s) => sum + s.durationSeconds);
  }

  int get currentStreakDays {
    if (_sessions.isEmpty) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final studyDates = _sessions
        .map((s) => DateTime(s.timestamp.year, s.timestamp.month, s.timestamp.day))
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
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));

    final List<double> result = List.filled(7, 0.0);

    for (final session in _sessions) {
      final sessionDate = DateTime(session.timestamp.year, session.timestamp.month, session.timestamp.day);
      final diffDays = sessionDate.difference(monday).inDays;
      if (diffDays >= 0 && diffDays < 7) {
        result[diffDays] += session.durationSeconds / 60.0;
      }
    }

    return result;
  }
}
