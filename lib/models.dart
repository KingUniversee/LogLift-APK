import 'dart:convert';

enum ExerciseType { strength, cardio, bodyweight }

enum WorkoutStatus { completed, cancelled }

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.muscle,
    required this.type,
    this.equipment = 'Barbell',
  });

  final String id;
  final String name;
  final String muscle;
  final ExerciseType type;
  final String equipment;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'muscle': muscle,
        'type': type.name,
        'equipment': equipment,
      };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] as String,
        name: json['name'] as String,
        muscle: json['muscle'] as String,
        type: ExerciseType.values.byName(json['type'] as String),
        equipment: json['equipment'] as String? ?? 'Barbell',
      );
}

class WorkoutPlan {
  const WorkoutPlan({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.exerciseIds,
    this.color = 0,
  });

  final String id;
  final String name;
  final String subtitle;
  final List<String> exerciseIds;
  final int color;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'subtitle': subtitle,
        'exerciseIds': exerciseIds,
        'color': color,
      };

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) => WorkoutPlan(
        id: json['id'] as String,
        name: json['name'] as String,
        subtitle: json['subtitle'] as String,
        exerciseIds: List<String>.from(json['exerciseIds'] as List<dynamic>),
        color: json['color'] as int? ?? 0,
      );
}

class SetLog {
  const SetLog({
    required this.reps,
    required this.weight,
    this.completed = true,
    this.duration = 0,
    this.distance = 0,
  });

  final int reps;
  final double weight;
  final bool completed;
  final int duration;
  final double distance;

  double get volume => (completed && weight > 0 && reps > 0) ? (weight * reps) : 0.0;

  Map<String, dynamic> toJson() => {
        'reps': reps,
        'weight': weight,
        'completed': completed,
        'duration': duration,
        'distance': distance,
      };

  factory SetLog.fromJson(Map<String, dynamic> json) => SetLog(
        reps: json['reps'] as int,
        weight: (json['weight'] as num).toDouble(),
        completed: json['completed'] as bool? ?? true,
        duration: json['duration'] as int? ?? 0,
        distance: (json['distance'] as num? ?? 0).toDouble(),
      );
}

class ExerciseLog {
  const ExerciseLog({required this.exerciseId, required this.sets});

  final String exerciseId;
  final List<SetLog> sets;

  int get completedSets => sets.where((set) => set.completed).length;
  double get volume => sets.where((set) => set.completed).fold(0, (sum, set) => sum + set.volume);

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'sets': sets.map((set) => set.toJson()).toList(),
      };

  factory ExerciseLog.fromJson(Map<String, dynamic> json) => ExerciseLog(
        exerciseId: json['exerciseId'] as String,
        sets: (json['sets'] as List<dynamic>)
            .map((set) => SetLog.fromJson(set as Map<String, dynamic>))
            .toList(),
      );
}

class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.planName,
    required this.startedAt,
    required this.durationMinutes,
    required this.logs,
    this.status = WorkoutStatus.completed,
    this.note = '',
  });

  final String id;
  final String planName;
  final DateTime startedAt;
  final int durationMinutes;
  final List<ExerciseLog> logs;
  final WorkoutStatus status;
  final String note;

  int get completedSets => logs.fold(0, (sum, log) => sum + log.completedSets);
  int get totalReps => logs.fold(0, (sum, log) => sum + log.sets.where((set) => set.completed).fold(0, (inner, set) => inner + set.reps));
  double get totalVolume => logs.fold(0, (sum, log) => sum + log.volume);

  Map<String, dynamic> toJson() => {
        'id': id,
        'planName': planName,
        'startedAt': startedAt.toIso8601String(),
        'durationMinutes': durationMinutes,
        'logs': logs.map((log) => log.toJson()).toList(),
        'status': status.name,
        'note': note,
      };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
        id: json['id'] as String,
        planName: json['planName'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        durationMinutes: json['durationMinutes'] as int,
        logs: (json['logs'] as List<dynamic>)
            .map((log) => ExerciseLog.fromJson(log as Map<String, dynamic>))
            .toList(),
        status: WorkoutStatus.values.byName(json['status'] as String? ?? 'completed'),
        note: json['note'] as String? ?? '',
      );
}

String encodeList<T>(List<T> values, Map<String, dynamic> Function(T) mapper) => jsonEncode(values.map(mapper).toList());
