import 'package:flutter/material.dart';

class Subject {
  final String id;
  final String name;
  final int colorValue;
  final int iconCodePoint;
  final double weeklyTargetHours;

  const Subject({
    required this.id,
    required this.name,
    required this.colorValue,
    this.iconCodePoint = 0xe120, // Icons.book.codePoint
    this.weeklyTargetHours = 5.0,
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
      };

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'] as String,
        name: json['name'] as String,
        colorValue: json['colorValue'] as int,
        iconCodePoint: json['iconCodePoint'] as int? ?? 0xe120,
        weeklyTargetHours: (json['weeklyTargetHours'] as num?)?.toDouble() ?? 5.0,
      );

  Subject copyWith({
    String? id,
    String? name,
    int? colorValue,
    int? iconCodePoint,
    double? weeklyTargetHours,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      weeklyTargetHours: weeklyTargetHours ?? this.weeklyTargetHours,
    );
  }
}
