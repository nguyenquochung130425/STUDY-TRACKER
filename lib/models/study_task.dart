import 'package:intl/intl.dart';

class StudyTask {
  final String id;
  final String title;
  final String description;
  final String? subjectId;
  final DateTime? dueDate;
  final bool isCompleted;

  const StudyTask({
    required this.id,
    required this.title,
    this.description = '',
    this.subjectId,
    this.dueDate,
    this.isCompleted = false,
  });

  /// Hiển thị hạn nộp dạng dd/MM/yyyy
  String get formattedDueDate {
    if (dueDate == null) return 'Không có hạn';
    return DateFormat('dd/MM/yyyy').format(dueDate!);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'subjectId': subjectId,
        'dueDate': dueDate?.toIso8601String(),
        'isCompleted': isCompleted,
      };

  factory StudyTask.fromJson(Map<String, dynamic> json) => StudyTask(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        subjectId: json['subjectId'] as String?,
        dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
        isCompleted: json['isCompleted'] as bool? ?? false,
      );

  Map<String, dynamic> toDbMap() => {
        'id': id,
        'title': title,
        'subject_id': subjectId ?? '',
        'description': description,
        'due_date': dueDate?.toIso8601String() ?? '',
        'is_completed': isCompleted ? 1 : 0,
        'priority': 'medium',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

  factory StudyTask.fromDbMap(Map<String, dynamic> map) => StudyTask(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String? ?? '',
        subjectId: (map['subject_id'] as String?)?.isNotEmpty == true
            ? map['subject_id'] as String
            : null,
        dueDate: map['due_date'] != null && (map['due_date'] as String).isNotEmpty
            ? DateTime.tryParse(map['due_date'] as String)
            : null,
        isCompleted: map['is_completed'] == 1,
      );

  StudyTask copyWith({
    String? id,
    String? title,
    String? description,
    String? subjectId,
    DateTime? dueDate,
    bool? isCompleted,
  }) {
    return StudyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subjectId: subjectId ?? this.subjectId,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
