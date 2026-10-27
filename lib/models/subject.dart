import 'package:flutter/material.dart';

class Subject {
  final String id;
  final String name;
  final int colorValue;
  final int iconCodePoint;
  final double weeklyTargetHours;
  final String code;
  final int credits;
  final String lecturer;
  final String semester;

  const Subject({
    required this.id,
    required this.name,
    required this.colorValue,
    this.iconCodePoint = 0xe120, // Icons.book.codePoint
    this.weeklyTargetHours = 5.0,
    this.code = '',
    this.credits = 3,
    this.lecturer = '',
    this.semester = 'Học kỳ 1 2026-2027',
  });

  Color get color => Color(colorValue);

  IconData get icon {
    switch (iconCodePoint) {
      case 0xe158:
        return Icons.calculate;
      case 0xe197:
        return Icons.code;
      case 0xe357:
        return Icons.language;
      case 0xe556:
        return Icons.science;
      case 0xe120:
      default:
        return Icons.menu_book;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        'iconCodePoint': iconCodePoint,
        'weeklyTargetHours': weeklyTargetHours,
        'code': code,
        'credits': credits,
        'lecturer': lecturer,
        'semester': semester,
      };

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'] as String,
        name: json['name'] as String,
        colorValue: json['colorValue'] as int,
        iconCodePoint: json['iconCodePoint'] as int? ?? 0xe120,
        weeklyTargetHours: (json['weeklyTargetHours'] as num?)?.toDouble() ?? 5.0,
        code: json['code'] as String? ?? '',
        credits: json['credits'] as int? ?? 3,
        lecturer: json['lecturer'] as String? ?? '',
        semester: json['semester'] as String? ?? 'Học kỳ 1 2026-2027',
      );

  Map<String, dynamic> toDbMap() => {
        'id': id,
        'name': name,
        'code': code,
        'credits': credits,
        'lecturer': lecturer,
        'semester': semester,
        'color_value': colorValue,
        'icon_code_point': iconCodePoint,
        'weekly_target_hours': weeklyTargetHours,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

  factory Subject.fromDbMap(Map<String, dynamic> map) => Subject(
        id: map['id'] as String,
        name: map['name'] as String,
        code: map['code'] as String? ?? '',
        credits: (map['credits'] as num?)?.toInt() ?? 3,
        lecturer: map['lecturer'] as String? ?? '',
        semester: map['semester'] as String? ?? 'Học kỳ 1 2026-2027',
        colorValue: (map['color_value'] as num).toInt(),
        iconCodePoint: (map['icon_code_point'] as num?)?.toInt() ?? 0xe120,
        weeklyTargetHours: (map['weekly_target_hours'] as num?)?.toDouble() ?? 5.0,
      );

  Subject copyWith({
    String? id,
    String? name,
    int? colorValue,
    int? iconCodePoint,
    double? weeklyTargetHours,
    String? code,
    int? credits,
    String? lecturer,
    String? semester,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      weeklyTargetHours: weeklyTargetHours ?? this.weeklyTargetHours,
      code: code ?? this.code,
      credits: credits ?? this.credits,
      lecturer: lecturer ?? this.lecturer,
      semester: semester ?? this.semester,
    );
  }
}
