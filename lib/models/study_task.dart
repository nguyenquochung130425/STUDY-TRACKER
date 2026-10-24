enum TaskPriority { low, medium, urgent }

class StudyTask {
  final String id;
  final String title;
  final String description;
  final String? subjectId;
  final DateTime? dueDate;
  final bool isCompleted;
  final TaskPriority priority;

  const StudyTask({
    required this.id,
    required this.title,
    this.description = '',
    this.subjectId,
    this.dueDate,
    this.isCompleted = false,
    this.priority = TaskPriority.medium,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'subjectId': subjectId,
    'dueDate': dueDate?.toIso8601String(),
    'isCompleted': isCompleted,
    'priority': priority.name,
  };

  factory StudyTask.fromJson(Map<String, dynamic> json) => StudyTask(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    subjectId: json['subjectId'] as String?,
    dueDate: json['dueDate'] != null
        ? DateTime.parse(json['dueDate'] as String)
        : null,
    isCompleted: json['isCompleted'] as bool? ?? false,
    priority: TaskPriority.values.firstWhere(
      (priority) => priority.name == json['priority'],
      orElse: () => TaskPriority.medium,
    ),
  );

  StudyTask copyWith({
    String? id,
    String? title,
    String? description,
    String? subjectId,
    bool clearSubjectId = false,
    DateTime? dueDate,
    bool clearDueDate = false,
    bool? isCompleted,
    TaskPriority? priority,
  }) {
    return StudyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subjectId: clearSubjectId ? null : subjectId ?? this.subjectId,
      dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
    );
  }
}
