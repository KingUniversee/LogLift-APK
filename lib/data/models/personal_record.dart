enum PRType {
  highestWeight('Highest Weight', 'kg'),
  mostReps('Most Reps', 'reps'),
  highestVolume('Highest Volume', 'kg'),
  longestDuration('Longest Duration', 'sec'),
  longestDistance('Longest Distance', 'km');

  const PRType(this.displayName, this.defaultUnit);
  final String displayName;
  final String defaultUnit;

  static PRType fromString(String val) {
    return PRType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => PRType.highestWeight,
    );
  }
}

class PersonalRecord {
  const PersonalRecord({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.recordType,
    required this.value,
    required this.sessionId,
    required this.achievedAt,
  });

  final String id;
  final String exerciseId;
  final String exerciseName;
  final PRType recordType;
  final double value;
  final String sessionId;
  final DateTime achievedAt;

  PersonalRecord copyWith({
    String? id,
    String? exerciseId,
    String? exerciseName,
    PRType? recordType,
    double? value,
    String? sessionId,
    DateTime? achievedAt,
  }) {
    return PersonalRecord(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      recordType: recordType ?? this.recordType,
      value: value ?? this.value,
      sessionId: sessionId ?? this.sessionId,
      achievedAt: achievedAt ?? this.achievedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'record_type': recordType.name,
        'value': value,
        'session_id': sessionId,
        'achieved_at': achievedAt.toIso8601String(),
      };

  factory PersonalRecord.fromMap(Map<String, dynamic> map) => PersonalRecord(
        id: map['id'] as String,
        exerciseId: map['exercise_id'] as String,
        exerciseName: map['exercise_name'] as String? ?? 'Exercise',
        recordType: PRType.fromString(map['record_type'] as String),
        value: (map['value'] as num).toDouble(),
        sessionId: map['session_id'] as String,
        achievedAt: DateTime.parse(map['achieved_at'] as String),
      );
}
