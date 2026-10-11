class StudyTask {
  final String id;
  final String title;
  final String? subjectId;
  final DateTime? dueDate;
  final bool isCompleted;

  const StudyTask({
    required this.id,
    required this.title,
    this.subjectId,
    this.dueDate,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subjectId': subjectId,
        'dueDate': dueDate?.toIso8601String(),
        'isCompleted': isCompleted,
      };

  factory StudyTask.fromJson(Map<String, dynamic> json) => StudyTask(
        id: json['id'] as String,
        title: json['title'] as String,
        subjectId: json['subjectId'] as String?,
        dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
        isCompleted: json['isCompleted'] as bool? ?? false,
      );

  StudyTask copyWith({
    String? id,
    String? title,
    String? subjectId,
    DateTime? dueDate,
    bool? isCompleted,
  }) {
    return StudyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      subjectId: subjectId ?? this.subjectId,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
