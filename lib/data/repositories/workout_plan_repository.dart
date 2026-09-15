import 'package:mongo_dart/mongo_dart.dart';
import 'package:uuid/uuid.dart';
import '../database/mongo_database.dart';
import '../models/workout_plan.dart';

class WorkoutPlanRepository {
  WorkoutPlanRepository([MongoDatabase? db]) : _db = db ?? MongoDatabase.instance;
  final MongoDatabase _db;

  Future<List<WorkoutPlan>> getPlans({String? query}) async {
    final collection = await _db.plansCollection;
    final docs = await collection.find(where.sortBy('created_at', descending: true)).toList();

    var plans = docs.map((doc) {
      final days = List<int>.from(doc['days_of_week'] as List? ?? []);
      final rawExercises = doc['exercises'] as List? ?? [];
      final exercises = rawExercises.map((e) => PlanExercise.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      return WorkoutPlan.fromMap(doc, days: days, exercises: exercises);
    }).toList();

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      plans = plans.where((p) {
        return p.name.toLowerCase().contains(q) || p.description.toLowerCase().contains(q);
      }).toList();
    }

    return plans;
  }

  Future<WorkoutPlan?> getPlanById(String id) async {
    final collection = await _db.plansCollection;
    final doc = await collection.findOne(where.eq('id', id));
    if (doc == null) return null;

    final days = List<int>.from(doc['days_of_week'] as List? ?? []);
    final rawExercises = doc['exercises'] as List? ?? [];
    final exercises = rawExercises.map((e) => PlanExercise.fromMap(Map<String, dynamic>.from(e as Map))).toList();

    return WorkoutPlan.fromMap(doc, days: days, exercises: exercises);
  }

  Future<WorkoutPlan?> getTodayPlan(DateTime date) async {
    final all = await getPlans();
    final matches = all.where((p) => p.isScheduledFor(date)).toList();
    if (matches.isEmpty) return null;
    return matches.first;
  }

  Future<void> savePlan(WorkoutPlan plan) async {
    final collection = await _db.plansCollection;
    final doc = plan.toMap()
      ..['_id'] = plan.id
      ..['days_of_week'] = plan.daysOfWeek
      ..['exercises'] = plan.exercises.map((e) => e.toMap()).toList();

    await collection.replaceOne(
      where.eq('id', plan.id),
      doc,
      upsert: true,
    );
  }

  Future<void> deletePlan(String id) async {
    final collection = await _db.plansCollection;
    await collection.deleteOne(where.eq('id', id));
  }

  Future<WorkoutPlan?> duplicatePlan(String id) async {
    final original = await getPlanById(id);
    if (original == null) return null;

    final newId = const Uuid().v4();
    final newExercises = original.exercises.map((e) {
      return e.copyWith(id: const Uuid().v4(), planId: newId);
    }).toList();

    final duplicated = WorkoutPlan(
      id: newId,
      name: '${original.name} (Copy)',
      description: original.description,
      colorIndex: (original.colorIndex + 1) % 4,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      daysOfWeek: List<int>.from(original.daysOfWeek),
      exercises: newExercises,
    );

    await savePlan(duplicated);
    return duplicated;
  }
}
