class GradeEntry {
  final String id;
  final String subjectId;
  final String title;
  final double score;
  final double maxScore;
  final double weight;
  final DateTime createdAt;

  const GradeEntry({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.score,
    required this.maxScore,
    required this.weight,
    required this.createdAt,
  });

  double get normalizedScore => score / maxScore * 10;

  Map<String, dynamic> toJson() => {
    'id': id,
    'subjectId': subjectId,
    'title': title,
    'score': score,
    'maxScore': maxScore,
    'weight': weight,
    'createdAt': createdAt.toIso8601String(),
  };

  factory GradeEntry.fromJson(Map<String, dynamic> json) => GradeEntry(
    id: json['id'] as String,
    subjectId: json['subjectId'] as String,
    title: json['title'] as String,
    score: (json['score'] as num).toDouble(),
    maxScore: (json['maxScore'] as num).toDouble(),
    weight: (json['weight'] as num).toDouble(),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  Map<String, dynamic> toDbMap() => {
    'id': id,
    'subject_id': subjectId,
    'title': title,
    'score': score,
    'max_score': maxScore,
    'weight': weight,
    'created_at': createdAt.toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
  };

  factory GradeEntry.fromDbMap(Map<String, dynamic> map) => GradeEntry(
    id: map['id'] as String,
    subjectId: map['subject_id'] as String,
    title: map['title'] as String,
    score: (map['score'] as num).toDouble(),
    maxScore: (map['max_score'] as num?)?.toDouble() ?? 10.0,
    weight: (map['weight'] as num?)?.toDouble() ?? 10.0,
    createdAt: DateTime.parse(map['created_at'] as String),
  );
}
