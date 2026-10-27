enum ScheduleStatus {
  upcoming,
  ongoing,
  completed,
  otherDay,
}

class Schedule {
  final String id;
  final String subjectId;
  final int dayOfWeek; // 2: Thứ Hai, ..., 7: Thứ Bảy, 8: Chủ Nhật
  final String startTime; // "07:30"
  final String endTime; // "09:30"
  final String room; // "A1-203"
  final String? building;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  Schedule({
    required this.id,
    required this.subjectId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.room,
    this.building,
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get dayName {
    switch (dayOfWeek) {
      case 2:
        return 'Thứ Hai';
      case 3:
        return 'Thứ Ba';
      case 4:
        return 'Thứ Tư';
      case 5:
        return 'Thứ Năm';
      case 6:
        return 'Thứ Sáu';
      case 7:
        return 'Thứ Bảy';
      case 8:
        return 'Chủ Nhật';
      default:
        return 'Thứ $dayOfWeek';
    }
  }

  String get shortDayName {
    switch (dayOfWeek) {
      case 2:
        return 'T2';
      case 3:
        return 'T3';
      case 4:
        return 'T4';
      case 5:
        return 'T5';
      case 6:
        return 'T6';
      case 7:
        return 'T7';
      case 8:
        return 'CN';
      default:
        return 'T$dayOfWeek';
    }
  }

  String get timeSpan => '$startTime - $endTime';

  /// Quy đổi từ DateTime.weekday (1=Thứ 2 ... 7=Chủ nhật) sang chuẩn ngày VN (2..8)
  static int fromDateTimeWeekday(int weekday) {
    return weekday == DateTime.sunday ? 8 : weekday + 1;
  }

  /// Quy đổi từ chuẩn ngày VN (2..8) sang DateTime.weekday (1..7)
  int toDateTimeWeekday() {
    return dayOfWeek == 8 ? DateTime.sunday : dayOfWeek - 1;
  }

  bool get isToday => DateTime.now().weekday == toDateTimeWeekday();

  ScheduleStatus get status {
    final now = DateTime.now();
    if (!isToday) return ScheduleStatus.otherDay;

    final startParts = startTime.split(':');
    final endParts = endTime.split(':');
    if (startParts.length != 2 || endParts.length != 2) {
      return ScheduleStatus.otherDay;
    }

    final startHour = int.tryParse(startParts[0]) ?? 0;
    final startMin = int.tryParse(startParts[1]) ?? 0;
    final endHour = int.tryParse(endParts[0]) ?? 0;
    final endMin = int.tryParse(endParts[1]) ?? 0;

    final startDt = DateTime(now.year, now.month, now.day, startHour, startMin);
    final endDt = DateTime(now.year, now.month, now.day, endHour, endMin);

    if (now.isBefore(startDt)) {
      return ScheduleStatus.upcoming;
    } else if (now.isAfter(endDt)) {
      return ScheduleStatus.completed;
    } else {
      return ScheduleStatus.ongoing;
    }
  }

  Map<String, dynamic> toDbMap() => {
        'id': id,
        'subject_id': subjectId,
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'room': room,
        'building': building,
        'note': note,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Schedule.fromDbMap(Map<String, dynamic> map) => Schedule(
        id: map['id'] as String,
        subjectId: map['subject_id'] as String,
        dayOfWeek: (map['day_of_week'] as num).toInt(),
        startTime: map['start_time'] as String,
        endTime: map['end_time'] as String,
        room: map['room'] as String,
        building: map['building'] as String?,
        note: map['note'] as String?,
        createdAt: map['created_at'] != null
            ? DateTime.tryParse(map['created_at'] as String)
            : null,
        updatedAt: map['updated_at'] != null
            ? DateTime.tryParse(map['updated_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'dayOfWeek': dayOfWeek,
        'startTime': startTime,
        'endTime': endTime,
        'room': room,
        'building': building,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Schedule.fromJson(Map<String, dynamic> json) => Schedule(
        id: json['id'] as String,
        subjectId: json['subjectId'] as String,
        dayOfWeek: (json['dayOfWeek'] as num).toInt(),
        startTime: json['startTime'] as String,
        endTime: json['endTime'] as String,
        room: json['room'] as String,
        building: json['building'] as String?,
        note: json['note'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
      );

  Schedule copyWith({
    String? id,
    String? subjectId,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    String? room,
    String? building,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Schedule(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      building: building ?? this.building,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
