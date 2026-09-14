import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class WorkoutStorage {
  const WorkoutStorage(this.preferences);

  final SharedPreferences preferences;

  List<Exercise> loadExercises() {
    final value = preferences.getString('exercises');
    if (value == null) return defaultExercises;
    return (jsonDecode(value) as List<dynamic>)
        .map((item) => Exercise.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  List<WorkoutPlan> loadPlans() {
    final value = preferences.getString('plans');
    if (value == null) return defaultPlans;
    return (jsonDecode(value) as List<dynamic>)
        .map((item) => WorkoutPlan.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  List<WorkoutSession> loadSessions() {
    final value = preferences.getString('sessions');
    if (value == null) return [];
    return (jsonDecode(value) as List<dynamic>)
        .map((item) => WorkoutSession.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> save({required List<Exercise> exercises, required List<WorkoutPlan> plans, required List<WorkoutSession> sessions}) async {
    await preferences.setString('exercises', jsonEncode(exercises.map((item) => item.toJson()).toList()));
    await preferences.setString('plans', jsonEncode(plans.map((item) => item.toJson()).toList()));
    await preferences.setString('sessions', jsonEncode(sessions.map((item) => item.toJson()).toList()));
  }
}

const defaultExercises = [
  Exercise(id: 'bench', name: 'Bench Press', muscle: 'Chest', type: ExerciseType.strength),
  Exercise(id: 'row', name: 'Seated Cable Row', muscle: 'Back', type: ExerciseType.strength, equipment: 'Cable'),
  Exercise(id: 'squat', name: 'Back Squat', muscle: 'Legs', type: ExerciseType.strength),
  Exercise(id: 'run', name: 'Outdoor Run', muscle: 'Cardio', type: ExerciseType.cardio, equipment: 'None'),
  Exercise(id: 'pushup', name: 'Push Ups', muscle: 'Chest', type: ExerciseType.bodyweight, equipment: 'None'),
];

const defaultPlans = [
  WorkoutPlan(id: 'push', name: 'Push Day', subtitle: 'Chest, shoulders & triceps', exerciseIds: ['bench', 'pushup'], color: 0),
  WorkoutPlan(id: 'pull', name: 'Pull Day', subtitle: 'Back & biceps', exerciseIds: ['row'], color: 1),
  WorkoutPlan(id: 'legs', name: 'Leg Day', subtitle: 'Quads, glutes & calves', exerciseIds: ['squat'], color: 2),
];
