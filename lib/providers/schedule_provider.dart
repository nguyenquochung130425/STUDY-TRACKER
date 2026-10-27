import 'package:flutter/material.dart';
import '../core/database/database_helper.dart';
import '../models/schedule.dart';

class ScheduleProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Schedule> _allSchedules = [];
  int? _selectedDayFilter;
  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;

  ScheduleProvider() {
    loadSchedules();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get selectedDayFilter => _selectedDayFilter;
  String get searchQuery => _searchQuery;
  List<Schedule> get allSchedules => List.unmodifiable(_allSchedules);

  /// Lấy danh sách lịch học sau khi áp dụng bộ lọc ngày và tìm kiếm
  List<Schedule> get schedules {
    return _allSchedules.where((schedule) {
      // Lọc theo ngày
      if (_selectedDayFilter != null && schedule.dayOfWeek != _selectedDayFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Lịch học của ngày hôm nay
  List<Schedule> get todaySchedules {
    final todayVn = Schedule.fromDateTimeWeekday(DateTime.now().weekday);
    return _allSchedules.where((s) => s.dayOfWeek == todayVn).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Lịch học theo từng thứ trong tuần
  List<Schedule> getSchedulesForDay(int dayOfWeek) {
    return _allSchedules.where((s) => s.dayOfWeek == dayOfWeek).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  Future<void> loadSchedules() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allSchedules = await _dbHelper.getAllSchedules(
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
    } catch (e) {
      _errorMessage = 'Không thể tải lịch học: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setDayFilter(int? dayOfWeek) {
    _selectedDayFilter = dayOfWeek;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadSchedules();
  }

  Future<bool> addSchedule(Schedule schedule) async {
    try {
      await _dbHelper.insertSchedule(schedule);
      await loadSchedules();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể thêm lịch học: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSchedule(Schedule schedule) async {
    try {
      await _dbHelper.updateSchedule(schedule);
      await loadSchedules();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể cập nhật lịch học: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSchedule(String id) async {
    try {
      await _dbHelper.deleteSchedule(id);
      _allSchedules.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể xóa lịch học: $e';
      notifyListeners();
      return false;
    }
  }
}
