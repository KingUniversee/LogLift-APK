import 'exercise.dart';

enum WorkoutStatus {
  notStarted,
  inProgress,
  completed,
  cancelled;

  static WorkoutStatus fromString(String val) {
    return WorkoutStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => WorkoutStatus.completed,
    );
  }
}

class SetLog {
  const SetLog({
    required this.id,
    required this.exerciseLogId,
    required this.setNumber,
    this.weightKg = 0,
    this.reps = 0,
    this.durationSeconds = 0,
    this.distanceKm = 0,
    this.completed = true,
    this.notes = '',
  });

  final String id;
  final String exerciseLogId;
  final int setNumber;
  final double weightKg;
  final int reps;
  final int durationSeconds;
  final double distanceKm;
  final bool completed;
  final String notes;

  double get volume => completed ? (weightKg * reps) : 0;

  SetLog copyWith({
    String? id,
    String? exerciseLogId,
    int? setNumber,
    double? weightKg,
    int? reps,
    int? durationSeconds,
    double? distanceKm,
    bool? completed,
    String? notes,
  }) {
    return SetLog(
      id: id ?? this.id,
      exerciseLogId: exerciseLogId ?? this.exerciseLogId,
      setNumber: setNumber ?? this.setNumber,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceKm: distanceKm ?? this.distanceKm,
      completed: completed ?? this.completed,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'exercise_log_id': exerciseLogId,
        'set_number': setNumber,
        'weight_kg': weightKg,
        'reps': reps,
        'duration_seconds': durationSeconds,
        'distance_km': distanceKm,
        'completed': completed ? 1 : 0,
        'notes': notes,
      };

  factory SetLog.fromMap(Map<String, dynamic> map) => SetLog(
        id: map['id'] as String,
        exerciseLogId: map['exercise_log_id'] as String,
        setNumber: map['set_number'] as int? ?? 1,
        weightKg: (map['weight_kg'] as num? ?? 0).toDouble(),
        reps: map['reps'] as int? ?? 0,
        durationSeconds: map['duration_seconds'] as int? ?? 0,
        distanceKm: (map['distance_km'] as num? ?? 0).toDouble(),
        completed: (map['completed'] as int? ?? 1) == 1,
        notes: map['notes'] as String? ?? '',
      );
}

class ExerciseLog {
  const ExerciseLog({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.exerciseName,
    required this.exerciseType,
    required this.sortOrder,
    this.sets = const [],
  });

  final String id;
  final String sessionId;
  final String exerciseId;
  final String exerciseName;
  final ExerciseType exerciseType;
  final int sortOrder;
  final List<SetLog> sets;

  int get completedSets => sets.where((s) => s.completed).length;
  int get totalReps => sets.where((s) => s.completed).fold(0, (sum, s) => sum + s.reps);
  double get totalVolume => sets.where((s) => s.completed).fold(0.0, (sum, s) => sum + s.volume);
  double get maxWeight => sets.where((s) => s.completed).fold(0.0, (max, s) => s.weightKg > max ? s.weightKg : max);

  ExerciseLog copyWith({
    String? id,
    String? sessionId,
    String? exerciseId,
    String? exerciseName,
    ExerciseType? exerciseType,
    int? sortOrder,
    List<SetLog>? sets,
  }) {
    return ExerciseLog(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      exerciseType: exerciseType ?? this.exerciseType,
      sortOrder: sortOrder ?? this.sortOrder,
      sets: sets ?? this.sets,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'session_id': sessionId,
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'exercise_type': exerciseType.name,
        'sort_order': sortOrder,
      };

  factory ExerciseLog.fromMap(
    Map<String, dynamic> map, {
    List<SetLog> sets = const [],
  }) =>
      ExerciseLog(
        id: map['id'] as String,
        sessionId: map['session_id'] as String,
        exerciseId: map['exercise_id'] as String,
        exerciseName: map['exercise_name'] as String? ?? 'Exercise',
        exerciseType: ExerciseType.fromString(map['exercise_type'] as String? ?? 'strength'),
        sortOrder: map['sort_order'] as int? ?? 0,
        sets: sets,
      );
}

class WorkoutSession {
  const WorkoutSession({
    required this.id,
    this.planId,
    required this.planName,
    required this.startedAt,
    this.completedAt,
    this.durationSeconds = 0,
    this.status = WorkoutStatus.completed,
    this.note = '',
    this.logs = const [],
  });

  final String id;
  final String? planId;
  final String planName;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int durationSeconds;
  final WorkoutStatus status;
  final String note;
  final List<ExerciseLog> logs;

  int get durationMinutes => (durationSeconds / 60).ceil();
  int get completedSets => logs.fold(0, (sum, l) => sum + l.completedSets);
  int get totalReps => logs.fold(0, (sum, l) => sum + l.totalReps);
  double get totalVolume => logs.fold(0.0, (sum, l) => sum + l.totalVolume);
  int get exercisesCount => logs.length;

  WorkoutSession copyWith({
    String? id,
    String? planId,
    String? planName,
    DateTime? startedAt,
    DateTime? completedAt,
    int? durationSeconds,
    WorkoutStatus? status,
    String? note,
    List<ExerciseLog>? logs,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      status: status ?? this.status,
      note: note ?? this.note,
      logs: logs ?? this.logs,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'plan_id': planId,
        'plan_name': planName,
        'started_at': startedAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'duration_seconds': durationSeconds,
        'status': status.name,
        'note': note,
      };

  factory WorkoutSession.fromMap(
    Map<String, dynamic> map, {
    List<ExerciseLog> logs = const [],
  }) =>
      WorkoutSession(
        id: map['id'] as String,
        planId: map['plan_id'] as String?,
        planName: map['plan_name'] as String? ?? 'Workout',
        startedAt: DateTime.parse(map['started_at'] as String),
        completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at'] as String) : null,
        durationSeconds: map['duration_seconds'] as int? ?? 0,
        status: WorkoutStatus.fromString(map['status'] as String? ?? 'completed'),
        note: map['note'] as String? ?? '',
        logs: logs,
      );
}
