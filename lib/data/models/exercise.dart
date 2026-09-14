enum MuscleGroup {
  chest('Chest'),
  back('Back'),
  legs('Legs'),
  shoulders('Shoulders'),
  arms('Arms'),
  core('Core'),
  cardio('Cardio'),
  fullBody('Full Body');

  const MuscleGroup(this.displayName);
  final String displayName;

  static MuscleGroup fromString(String val) {
    return MuscleGroup.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase() || e.displayName.toLowerCase() == val.toLowerCase(),
      orElse: () => MuscleGroup.fullBody,
    );
  }
}

enum ExerciseType {
  strength('Strength (Weight & Reps)'),
  weightAndReps('Weight + Reps'),
  repsOnly('Reps Only'),
  bodyweight('Bodyweight'),
  duration('Duration (Time)'),
  distance('Distance & Time'),
  cardio('Cardio');

  const ExerciseType(this.displayName);
  final String displayName;

  static ExerciseType fromString(String val) {
    return ExerciseType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase() || e.displayName.toLowerCase() == val.toLowerCase(),
      orElse: () => ExerciseType.strength,
    );
  }
}

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    required this.exerciseType,
    this.instructions = '',
    this.notes = '',
    this.isCustom = true,
    required this.createdAt,
  });

  final String id;
  final String name;
  final MuscleGroup muscleGroup;
  final String equipment;
  final ExerciseType exerciseType;
  final String instructions;
  final String notes;
  final bool isCustom;
  final DateTime createdAt;

  Exercise copyWith({
    String? id,
    String? name,
    MuscleGroup? muscleGroup,
    String? equipment,
    ExerciseType? exerciseType,
    String? instructions,
    String? notes,
    bool? isCustom,
    DateTime? createdAt,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      equipment: equipment ?? this.equipment,
      exerciseType: exerciseType ?? this.exerciseType,
      instructions: instructions ?? this.instructions,
      notes: notes ?? this.notes,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'muscle_group': muscleGroup.name,
        'equipment': equipment,
        'exercise_type': exerciseType.name,
        'instructions': instructions,
        'notes': notes,
        'is_custom': isCustom ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
        id: map['id'] as String,
        name: map['name'] as String,
        muscleGroup: MuscleGroup.fromString(map['muscle_group'] as String),
        equipment: map['equipment'] as String? ?? 'Barbell',
        exerciseType: ExerciseType.fromString(map['exercise_type'] as String),
        instructions: map['instructions'] as String? ?? '',
        notes: map['notes'] as String? ?? '',
        isCustom: (map['is_custom'] as int? ?? 1) == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
