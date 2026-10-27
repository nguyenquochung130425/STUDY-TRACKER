class QuestionModel {
  final String id;
  final String assignmentId;
  final int questionNumber;
  final String content;
  final String? passage;
  final String? explanation;
  final List<ChoiceModel> choices;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuestionModel({
    required this.id,
    required this.assignmentId,
    required this.questionNumber,
    required this.content,
    this.passage,
    this.explanation,
    List<ChoiceModel>? choices,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : choices = choices ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  QuestionModel copyWith({
    String? id,
    String? assignmentId,
    int? questionNumber,
    String? content,
    String? passage,
    String? explanation,
    List<ChoiceModel>? choices,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      questionNumber: questionNumber ?? this.questionNumber,
      content: content ?? this.content,
      passage: passage ?? this.passage,
      explanation: explanation ?? this.explanation,
      choices: choices ?? this.choices,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toDbMap() => {
        'id': id,
        'assignment_id': assignmentId,
        'question_number': questionNumber,
        'content': content,
        'passage': passage,
        'explanation': explanation,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory QuestionModel.fromDbMap(
    Map<String, dynamic> map, {
    List<ChoiceModel> choices = const [],
  }) =>
      QuestionModel(
        id: map['id'] as String,
        assignmentId: map['assignment_id'] as String,
        questionNumber: (map['question_number'] as num?)?.toInt() ?? 1,
        content: map['content'] as String,
        passage: map['passage'] as String?,
        explanation: map['explanation'] as String?,
        choices: choices,
        createdAt: map['created_at'] != null
            ? DateTime.tryParse(map['created_at'] as String)
            : null,
        updatedAt: map['updated_at'] != null
            ? DateTime.tryParse(map['updated_at'] as String)
            : null,
      );
}

class ChoiceModel {
  final String id;
  final String questionId;
  final String label; // 'A', 'B', 'C', 'D'
  final String content;
  final bool isCorrect;

  ChoiceModel({
    required this.id,
    required this.questionId,
    required this.label,
    required this.content,
    this.isCorrect = false,
  });

  ChoiceModel copyWith({
    String? id,
    String? questionId,
    String? label,
    String? content,
    bool? isCorrect,
  }) {
    return ChoiceModel(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      label: label ?? this.label,
      content: content ?? this.content,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }

  Map<String, dynamic> toDbMap() => {
        'id': id,
        'question_id': questionId,
        'choice_label': label,
        'content': content,
        'is_correct': isCorrect ? 1 : 0,
      };

  factory ChoiceModel.fromDbMap(Map<String, dynamic> map) => ChoiceModel(
        id: map['id'] as String,
        questionId: map['question_id'] as String,
        label: map['choice_label'] as String,
        content: map['content'] as String,
        isCorrect: map['is_correct'] == 1,
      );
}
