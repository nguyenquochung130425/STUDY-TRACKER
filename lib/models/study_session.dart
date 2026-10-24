class StudySession {
  final String id;
  final String subjectId;
  final int durationSeconds;
  final DateTime timestamp;
  final String mode; // 'focus' | 'stopwatch'
  final String? note;

  const StudySession({
    required this.id,
    required this.subjectId,
    required this.durationSeconds,
    required this.timestamp,
    this.mode = 'focus',
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'subjectId': subjectId,
    'durationSeconds': durationSeconds,
    'timestamp': timestamp.toIso8601String(),
    'mode': mode,
    'note': note,
  };

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
    id: json['id'] as String,
    subjectId: json['subjectId'] as String,
    durationSeconds: json['durationSeconds'] as int,
    timestamp: DateTime.parse(json['timestamp'] as String),
    mode: json['mode'] as String? ?? 'focus',
    note: json['note'] as String?,
  );
}
