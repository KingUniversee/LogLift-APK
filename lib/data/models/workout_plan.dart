import 'exercise.dart';

class PlanExercise {
  const PlanExercise({
    required this.id,
    required this.planId,
    required this.exerciseId,
    required this.exerciseName,
    required this.exerciseMuscle,
    required this.exerciseType,
    required this.sortOrder,
    this.targetSets = 3,
    this.targetReps = 10,
    this.targetWeight = 0,
    this.targetDurationSeconds = 0,
    this.restSeconds = 60,
  });

  final String id;
  final String planId;
  final String exerciseId;
  final String exerciseName;
  final MuscleGroup exerciseMuscle;
  final ExerciseType exerciseType;
  final int sortOrder;
  final int targetSets;
  final int targetReps;
  final double targetWeight;
  final int targetDurationSeconds;
  final int restSeconds;

  PlanExercise copyWith({
    String? id,
    String? planId,
    String? exerciseId,
    String? exerciseName,
    MuscleGroup? exerciseMuscle,
    ExerciseType? exerciseType,
    int? sortOrder,
    int? targetSets,
    int? targetReps,
    double? targetWeight,
    int? targetDurationSeconds,
    int? restSeconds,
  }) {
    return PlanExercise(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      exerciseMuscle: exerciseMuscle ?? this.exerciseMuscle,
      exerciseType: exerciseType ?? this.exerciseType,
      sortOrder: sortOrder ?? this.sortOrder,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      targetWeight: targetWeight ?? this.targetWeight,
      targetDurationSeconds: targetDurationSeconds ?? this.targetDurationSeconds,
      restSeconds: restSeconds ?? this.restSeconds,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'plan_id': planId,
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'exercise_muscle': exerciseMuscle.name,
        'exercise_type': exerciseType.name,
        'sort_order': sortOrder,
        'target_sets': targetSets,
        'target_reps': targetReps,
        'target_weight': targetWeight,
        'target_duration_seconds': targetDurationSeconds,
        'rest_seconds': restSeconds,
      };

  factory PlanExercise.fromMap(Map<String, dynamic> map) => PlanExercise(
        id: map['id'] as String,
        planId: map['plan_id'] as String,
        exerciseId: map['exercise_id'] as String,
        exerciseName: map['exercise_name'] as String? ?? 'Exercise',
        exerciseMuscle: MuscleGroup.fromString(map['exercise_muscle'] as String? ?? 'FullBody'),
        exerciseType: ExerciseType.fromString(map['exercise_type'] as String? ?? 'strength'),
        sortOrder: map['sort_order'] as int? ?? 0,
        targetSets: map['target_sets'] as int? ?? 3,
        targetReps: map['target_reps'] as int? ?? 10,
        targetWeight: (map['target_weight'] as num? ?? 0).toDouble(),
        targetDurationSeconds: map['target_duration_seconds'] as int? ?? 0,
        restSeconds: map['rest_seconds'] as int? ?? 60,
      );
}

class WorkoutPlan {
  const WorkoutPlan({
    required this.id,
    required this.name,
    this.description = '',
    this.colorIndex = 0,
    required this.createdAt,
    required this.updatedAt,
    this.daysOfWeek = const [],
    this.exercises = const [],
  });

  final String id;
  final String name;
  final String description;
  final int colorIndex;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<int> daysOfWeek; // 0=Monday, 6=Sunday
  final List<PlanExercise> exercises;

  // Estimated duration in minutes: ~2.5 min per set
  int get estimatedDurationMinutes {
    final totalSets = exercises.fold<int>(0, (sum, e) => sum + e.targetSets);
    return totalSets == 0 ? 30 : (totalSets * 2.5).round();
  }

  bool isScheduledFor(DateTime date) {
    // DateTime.weekday is 1=Monday, 7=Sunday
    final dayIndex = date.weekday - 1;
    return daysOfWeek.contains(dayIndex);
  }

  String get daysFormatted {
    if (daysOfWeek.isEmpty) return 'Unscheduled';
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sorted = List<int>.from(daysOfWeek)..sort();
    return sorted.map((d) => dayNames[d]).join(', ');
  }

  WorkoutPlan copyWith({
    String? id,
    String? name,
    String? description,
    int? colorIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<int>? daysOfWeek,
    List<PlanExercise>? exercises,
  }) {
    return WorkoutPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorIndex: colorIndex ?? this.colorIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      exercises: exercises ?? this.exercises,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'color_index': colorIndex,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory WorkoutPlan.fromMap(
    Map<String, dynamic> map, {
    List<int> days = const [],
    List<PlanExercise> exercises = const [],
  }) =>
      WorkoutPlan(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String? ?? '',
        colorIndex: map['color_index'] as int? ?? 0,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
        daysOfWeek: days,
        exercises: exercises,
      );
}
