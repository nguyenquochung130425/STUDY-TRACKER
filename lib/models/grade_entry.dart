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
}
