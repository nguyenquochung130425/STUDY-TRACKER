import 'dart:async';
import 'package:flutter/material.dart';
import '../models/study_session.dart';
import 'study_provider.dart';

enum PomodoroMode { focus, shortBreak, longBreak }
enum PomodoroStatus { initial, running, paused, completed }

class PomodoroProvider extends ChangeNotifier {
  static const int defaultFocusSeconds = 25 * 60;
  static const int defaultShortBreakSeconds = 5 * 60;
  static const int defaultLongBreakSeconds = 15 * 60;

  PomodoroMode _mode = PomodoroMode.focus;
  PomodoroStatus _status = PomodoroStatus.initial;
  int _remainingSeconds = defaultFocusSeconds;
  int _totalSeconds = defaultFocusSeconds;
  String? _selectedSubjectId;
  int _completedPomodoros = 0;
  Timer? _timer;

  StudyProvider? _studyProvider;

  void updateStudyProvider(StudyProvider studyProvider) {
    _studyProvider = studyProvider;
    if (_selectedSubjectId == null && studyProvider.subjects.isNotEmpty) {
      _selectedSubjectId = studyProvider.subjects.first.id;
    }
  }

  PomodoroMode get mode => _mode;
  PomodoroStatus get status => _status;
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;
  String? get selectedSubjectId => _selectedSubjectId;
  int get completedPomodoros => _completedPomodoros;

  bool get isRunning => _status == PomodoroStatus.running;
  bool get isPaused => _status == PomodoroStatus.paused;

  double get progress {
    if (_totalSeconds == 0) return 0.0;
    return (_totalSeconds - _remainingSeconds) / _totalSeconds;
  }

  String get formattedTime {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void selectSubject(String? subjectId) {
    _selectedSubjectId = subjectId;
    notifyListeners();
  }

  void setMode(PomodoroMode mode) {
    _timer?.cancel();
    _mode = mode;
    _status = PomodoroStatus.initial;
    switch (mode) {
      case PomodoroMode.focus:
        _totalSeconds = defaultFocusSeconds;
        break;
      case PomodoroMode.shortBreak:
        _totalSeconds = defaultShortBreakSeconds;
        break;
      case PomodoroMode.longBreak:
        _totalSeconds = defaultLongBreakSeconds;
        break;
    }
    _remainingSeconds = _totalSeconds;
    notifyListeners();
  }

  void start() {
    if (_status == PomodoroStatus.running) return;

    _status = PomodoroStatus.running;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _onCompleted();
      }
    });
  }

  void pause() {
    if (_status != PomodoroStatus.running) return;
    _timer?.cancel();
    _status = PomodoroStatus.paused;
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _status = PomodoroStatus.initial;
    _remainingSeconds = _totalSeconds;
    notifyListeners();
  }

  void skip() {
    _timer?.cancel();
    _nextMode();
  }

  void _onCompleted() {
    _timer?.cancel();
    _status = PomodoroStatus.completed;

    if (_mode == PomodoroMode.focus) {
      _completedPomodoros++;
      // Lưu phiên học vào StudyProvider
      if (_studyProvider != null && _selectedSubjectId != null) {
        final session = StudySession(
          id: 'sess_${DateTime.now().millisecondsSinceEpoch}',
          subjectId: _selectedSubjectId!,
          durationSeconds: _totalSeconds,
          timestamp: DateTime.now(),
          mode: 'focus',
        );
        _studyProvider!.addSession(session);
      }
    }

    _nextMode();
  }

  void _nextMode() {
    if (_mode == PomodoroMode.focus) {
      if (_completedPomodoros % 4 == 0) {
        setMode(PomodoroMode.longBreak);
      } else {
        setMode(PomodoroMode.shortBreak);
      }
    } else {
      setMode(PomodoroMode.focus);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
