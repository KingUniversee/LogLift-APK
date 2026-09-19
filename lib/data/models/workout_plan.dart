import 'dart:convert';
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
    this.dayOfWeek,
    this.targetSets = 3,
    this.targetReps = 10,
    this.targetWeight = 0,
    this.targetDurationSeconds = 0,
    this.targetDistanceKm = 0,
    this.restSeconds = 60,
  });

  final String id;
  final String planId;
  final String exerciseId;
  final String exerciseName;
  final MuscleGroup exerciseMuscle;
  final ExerciseType exerciseType;
  final int sortOrder;
  final int? dayOfWeek; // 0=Mon ... 6=Sun, null if legacy/all days
  final int targetSets;
  final int targetReps;
  final double targetWeight;
  final int targetDurationSeconds;
  final double targetDistanceKm;
  final int restSeconds;

  String get targetSummary {
    switch (exerciseType) {
      case ExerciseType.duration:
        final duration = targetDurationSeconds > 0 ? targetDurationSeconds : 60;
        return '$targetSets sets × ${_formatDuration(duration)}';
      case ExerciseType.distance:
        final dist = targetDistanceKm > 0 ? '${targetDistanceKm.toStringAsFixed(targetDistanceKm.truncateToDouble() == targetDistanceKm ? 0 : 1)} km' : '';
        final dur = targetDurationSeconds > 0 ? _formatDuration(targetDurationSeconds) : '';
        final parts = [if (dist.isNotEmpty) dist, if (dur.isNotEmpty) dur].join(' · ');
        return '$targetSets sets${parts.isNotEmpty ? ' × $parts' : ''}';
      case ExerciseType.cardio:
        final dur = targetDurationSeconds > 0 ? _formatDuration(targetDurationSeconds) : '20m';
        if (targetDistanceKm > 0) {
          final dist = '${targetDistanceKm.toStringAsFixed(targetDistanceKm.truncateToDouble() == targetDistanceKm ? 0 : 1)} km';
          return '$targetSets sets × $dist · $dur';
        }
        return '$targetSets sets × $dur';
      case ExerciseType.strength:
      case ExerciseType.weightAndReps:
        if (targetWeight > 0) {
          final wStr = targetWeight.truncateToDouble() == targetWeight ? targetWeight.toStringAsFixed(0) : targetWeight.toStringAsFixed(1);
          return '$targetSets sets × $targetReps reps @ $wStr kg';
        }
        return '$targetSets sets × $targetReps reps';
      case ExerciseType.repsOnly:
      case ExerciseType.bodyweight:
        return '$targetSets sets × $targetReps reps';
    }
  }

  static String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final mins = seconds ~/ 60;
    final rem = seconds % 60;
    if (rem == 0) return '${mins}m';
    return '${mins}m ${rem}s';
  }

  PlanExercise copyWith({
    String? id,
    String? planId,
    String? exerciseId,
    String? exerciseName,
    MuscleGroup? exerciseMuscle,
    ExerciseType? exerciseType,
    int? sortOrder,
    int? dayOfWeek,
    bool clearDayOfWeek = false,
    int? targetSets,
    int? targetReps,
    double? targetWeight,
    int? targetDurationSeconds,
    double? targetDistanceKm,
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
      dayOfWeek: clearDayOfWeek ? null : (dayOfWeek ?? this.dayOfWeek),
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      targetWeight: targetWeight ?? this.targetWeight,
      targetDurationSeconds: targetDurationSeconds ?? this.targetDurationSeconds,
      targetDistanceKm: targetDistanceKm ?? this.targetDistanceKm,
      restSeconds: restSeconds ?? this.restSeconds,
    );
  }

  Map<String, dynamic> toMap() {
    // Dual encoding: if dayOfWeek != null, encode day into sort_order as (dayOfWeek + 1) * 1000 + (sortOrder % 1000).
    // This allows older backends without day_of_week schema to persist day assignment reliably.
    final encodedSortOrder = dayOfWeek != null ? ((dayOfWeek! + 1) * 1000 + (sortOrder % 1000)) : sortOrder;

    return {
      'id': id,
      'plan_id': planId,
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'exercise_muscle': exerciseMuscle.name,
      'exercise_type': exerciseType.name,
      'sort_order': encodedSortOrder,
      'day_of_week': dayOfWeek,
      'target_sets': targetSets,
      'target_reps': targetReps,
      'target_weight': targetWeight > 0 ? targetWeight : (targetDistanceKm > 0 ? targetDistanceKm : 0.0),
      'target_duration_seconds': targetDurationSeconds,
      'target_distance_km': targetDistanceKm,
      'rest_seconds': restSeconds,
    };
  }

  factory PlanExercise.fromMap(Map<String, dynamic> map) {
    final rawSortOrder = map['sort_order'] as int? ?? 0;
    final explicitDay = map['day_of_week'] as int?;
    final dayOfWeek = explicitDay ?? (rawSortOrder >= 1000 ? (rawSortOrder ~/ 1000) - 1 : null);
    final sortOrder = rawSortOrder >= 1000 ? (rawSortOrder % 1000) : rawSortOrder;

    final exerciseType = ExerciseType.fromString(map['exercise_type'] as String? ?? 'strength');
    final rawWeight = (map['target_weight'] as num? ?? 0).toDouble();
    final rawDistance = (map['target_distance_km'] as num? ?? 0).toDouble();

    final targetDistanceKm = rawDistance > 0
        ? rawDistance
        : ((exerciseType == ExerciseType.distance || exerciseType == ExerciseType.cardio) ? rawWeight : 0.0);
    final targetWeight = (exerciseType == ExerciseType.distance || exerciseType == ExerciseType.cardio) && rawDistance == 0
        ? 0.0
        : rawWeight;

    return PlanExercise(
      id: map['id'] as String,
      planId: map['plan_id'] as String,
      exerciseId: map['exercise_id'] as String,
      exerciseName: map['exercise_name'] as String? ?? 'Exercise',
      exerciseMuscle: MuscleGroup.fromString(map['exercise_muscle'] as String? ?? 'FullBody'),
      exerciseType: exerciseType,
      sortOrder: sortOrder,
      dayOfWeek: dayOfWeek,
      targetSets: map['target_sets'] as int? ?? 3,
      targetReps: map['target_reps'] as int? ?? 10,
      targetWeight: targetWeight,
      targetDurationSeconds: map['target_duration_seconds'] as int? ?? 0,
      targetDistanceKm: targetDistanceKm,
      restSeconds: map['rest_seconds'] as int? ?? 60,
    );
  }
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
    this.isRotating = true,
    this.currentSplitIndex = 0,
    this.leaveDates = const [],
    this.lastCompletedDate,
    this.lastCompletedSplitIndex,
  });

  final String id;
  final String name;
  final String description;
  final int colorIndex;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<int> daysOfWeek; // 0=Day 1, 1=Day 2... (or 0=Mon, 6=Sun in legacy)
  final List<PlanExercise> exercises;
  final bool isRotating;
  final int currentSplitIndex;
  final List<String> leaveDates; // formatted 'yyyy-MM-dd'
  final DateTime? lastCompletedDate;
  final int? lastCompletedSplitIndex;

  static String formatDateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  bool isLeaveForDate(DateTime date) {
    return leaveDates.contains(formatDateKey(date));
  }

  bool isOffDay(int dayIndex) {
    return getExercisesForDay(dayIndex).isEmpty;
  }

  int getEffectiveSplitIndexForDate(DateTime date) {
    if (!isRotating) {
      return (date.weekday - 1) % 7;
    }
    if (daysOfWeek.isEmpty) return 0;
    final totalDays = daysOfWeek.length;
    final safeIndex = currentSplitIndex % totalDays;

    // If safeIndex is an OFF day, check whether it was already observed on a prior non-leave day
    if (isOffDay(safeIndex) && lastCompletedDate != null) {
      final lastDateOnly = DateTime(lastCompletedDate!.year, lastCompletedDate!.month, lastCompletedDate!.day);
      final targetDateOnly = DateTime(date.year, date.month, date.day);
      final daysDiff = targetDateOnly.difference(lastDateOnly).inDays;

      if (daysDiff > 0) {
        var leavesInBetween = 0;
        for (var i = 1; i < daysDiff; i++) {
          final intermediateDate = lastDateOnly.add(Duration(days: i));
          if (isLeaveForDate(intermediateDate)) {
            leavesInBetween++;
          }
        }
        final nonLeaveDaysPassed = (daysDiff - 1) - leavesInBetween;
        if (nonLeaveDaysPassed >= 1) {
          return (safeIndex + 1) % totalDays;
        }
      }
    }

    return safeIndex;
  }

  bool get hasDayWiseConfiguration => exercises.any((e) => e.dayOfWeek != null);

  List<PlanExercise> getExercisesForDay(int dayIndex) {
    if (hasDayWiseConfiguration) {
      final dayList = exercises.where((e) => e.dayOfWeek == dayIndex).toList();
      dayList.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return dayList;
    }
    // Backward compatibility for legacy plans without day tags
    if (daysOfWeek.contains(dayIndex) || daysOfWeek.isEmpty) {
      return exercises;
    }
    return [];
  }

  int estimatedDurationMinutesForDay(int dayIndex) {
    final dayEx = getExercisesForDay(dayIndex);
    final totalSets = dayEx.fold<int>(0, (sum, e) => sum + e.targetSets);
    return totalSets == 0 ? 0 : (totalSets * 2.5).round();
  }

  // Estimated duration in minutes: ~2.5 min per set
  int get estimatedDurationMinutes {
    if (hasDayWiseConfiguration && daysOfWeek.isNotEmpty) {
      final activeDays = daysOfWeek.where((d) => getExercisesForDay(d).isNotEmpty).toList();
      if (activeDays.isEmpty) return 30;
      final totalSets = exercises.fold<int>(0, (sum, e) => sum + e.targetSets);
      final avgSets = totalSets / activeDays.length;
      return avgSets == 0 ? 30 : (avgSets * 2.5).round();
    }
    final totalSets = exercises.fold<int>(0, (sum, e) => sum + e.targetSets);
    return totalSets == 0 ? 30 : (totalSets * 2.5).round();
  }

  bool isScheduledFor(DateTime date) {
    if (daysOfWeek.isEmpty) return false;
    return true;
  }

  String get daysFormatted {
    if (daysOfWeek.isEmpty) return 'Unscheduled';
    final sorted = List<int>.from(daysOfWeek)..sort();
    if (sorted.length == 1) {
      return isRotating ? '1 Day Split (Day 1)' : '1 Day (Day ${sorted.first + 1})';
    }
    final isConsecutive = sorted.last - sorted.first == sorted.length - 1;
    if (isConsecutive && sorted.first == 0) {
      return isRotating
          ? '${sorted.length} Day Rotating Split (Day 1 - Day ${sorted.length})'
          : '${sorted.length} Days (Day 1 - Day ${sorted.length})';
    }
    return '${sorted.length} Days (${sorted.map((d) => 'Day ${d + 1}').join(', ')})';
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
    bool? isRotating,
    int? currentSplitIndex,
    List<String>? leaveDates,
    DateTime? lastCompletedDate,
    int? lastCompletedSplitIndex,
    bool clearLastCompletedDate = false,
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
      isRotating: isRotating ?? this.isRotating,
      currentSplitIndex: currentSplitIndex ?? this.currentSplitIndex,
      leaveDates: leaveDates ?? this.leaveDates,
      lastCompletedDate: clearLastCompletedDate ? null : (lastCompletedDate ?? this.lastCompletedDate),
      lastCompletedSplitIndex: lastCompletedSplitIndex ?? this.lastCompletedSplitIndex,
    );
  }

  String get cleanDescription {
    final regex = RegExp(r'\n?<!--liftlog_meta:.*?-->', dotAll: true);
    return description.replaceAll(regex, '').trim();
  }

  Map<String, dynamic> toMap() {
    final meta = {
      'rot': isRotating,
      'csi': currentSplitIndex,
      'lvs': leaveDates,
      'lcd': lastCompletedDate?.toIso8601String(),
      'lcs': lastCompletedSplitIndex,
    };
    final metaJson = jsonEncode(meta);
    final baseDesc = cleanDescription;
    final fullDescription = baseDesc.isEmpty ? '<!--liftlog_meta:$metaJson-->' : '$baseDesc\n<!--liftlog_meta:$metaJson-->';

    return {
      'id': id,
      'name': name,
      'description': fullDescription,
      'color_index': colorIndex,
      'is_rotating': isRotating,
      'current_split_index': currentSplitIndex,
      'leave_dates': leaveDates,
      'last_completed_date': lastCompletedDate?.toIso8601String(),
      'last_completed_split_index': lastCompletedSplitIndex,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory WorkoutPlan.fromMap(
    Map<String, dynamic> map, {
    List<int> days = const [],
    List<PlanExercise> exercises = const [],
  }) {
    var rotating = map['is_rotating'] as bool?;
    var splitIndex = map['current_split_index'] as int?;
    var leaves = map['leave_dates'] != null ? List<String>.from(map['leave_dates'] as List) : null;
    var lastDate = map['last_completed_date'] != null
        ? DateTime.tryParse(map['last_completed_date'] as String)
        : null;
    var lastSplit = map['last_completed_split_index'] as int?;

    final rawDesc = map['description'] as String? ?? '';
    final metaMatch = RegExp(r'<!--liftlog_meta:(.*?)-->', dotAll: true).firstMatch(rawDesc);
    if (metaMatch != null) {
      try {
        final meta = jsonDecode(metaMatch.group(1)!) as Map<String, dynamic>;
        rotating ??= meta['rot'] as bool?;
        splitIndex ??= meta['csi'] as int?;
        leaves ??= meta['lvs'] != null ? List<String>.from(meta['lvs'] as List) : null;
        lastDate ??= meta['lcd'] != null ? DateTime.tryParse(meta['lcd'] as String) : null;
        lastSplit ??= meta['lcs'] as int?;
      } catch (_) {}
    }

    final cleanDesc = rawDesc.replaceAll(RegExp(r'\n?<!--liftlog_meta:.*?-->', dotAll: true), '').trim();

    return WorkoutPlan(
      id: map['id'] as String,
      name: map['name'] as String,
      description: cleanDesc,
      colorIndex: map['color_index'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      daysOfWeek: days.isNotEmpty ? days : List<int>.from(map['days_of_week'] as List? ?? []),
      exercises: exercises.isNotEmpty
          ? exercises
          : (map['exercises'] as List? ?? [])
              .map((e) => PlanExercise.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList(),
      isRotating: rotating ?? true,
      currentSplitIndex: splitIndex ?? 0,
      leaveDates: leaves ?? const [],
      lastCompletedDate: lastDate,
      lastCompletedSplitIndex: lastSplit,
    );
  }
}
