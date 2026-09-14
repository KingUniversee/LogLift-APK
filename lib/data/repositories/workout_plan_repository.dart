import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/workout_plan.dart';

class WorkoutPlanRepository {
  WorkoutPlanRepository([Database? db]) : _db = db;
  final Database? _db;

  Future<Database> get _database async => _db ?? await AppDatabase.instance.database;

  Future<List<WorkoutPlan>> getPlans({String? query}) async {
    final db = await _database;
    final whereString = query != null && query.trim().isNotEmpty ? 'name LIKE ? OR description LIKE ?' : null;
    final whereArgs = query != null && query.trim().isNotEmpty ? ['%${query.trim()}%', '%${query.trim()}%'] : null;

    final planMaps = await db.query(
      'workout_plans',
      where: whereString,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    final plans = <WorkoutPlan>[];
    for (final map in planMaps) {
      final planId = map['id'] as String;
      final days = await _getPlanDays(db, planId);
      final exercises = await _getPlanExercises(db, planId);
      plans.add(WorkoutPlan.fromMap(map, days: days, exercises: exercises));
    }
    return plans;
  }

  Future<WorkoutPlan?> getPlanById(String id) async {
    final db = await _database;
    final maps = await db.query('workout_plans', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;

    final days = await _getPlanDays(db, id);
    final exercises = await _getPlanExercises(db, id);
    return WorkoutPlan.fromMap(maps.first, days: days, exercises: exercises);
  }

  Future<WorkoutPlan?> getTodayPlan(DateTime date) async {
    final all = await getPlans();
    final matches = all.where((p) => p.isScheduledFor(date)).toList();
    if (matches.isEmpty) return null;
    return matches.first;
  }

  Future<void> savePlan(WorkoutPlan plan) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.insert(
        'workout_plans',
        plan.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Replace scheduled days
      await txn.delete('workout_plan_days', where: 'plan_id = ?', whereArgs: [plan.id]);
      for (final day in plan.daysOfWeek) {
        await txn.insert('workout_plan_days', {
          'id': const Uuid().v4(),
          'plan_id': plan.id,
          'day_of_week': day,
        });
      }

      // Replace plan exercises
      await txn.delete('plan_exercises', where: 'plan_id = ?', whereArgs: [plan.id]);
      for (var i = 0; i < plan.exercises.length; i++) {
        final ex = plan.exercises[i].copyWith(sortOrder: i);
        await txn.insert('plan_exercises', ex.toMap());
      }
    });
  }

  Future<void> deletePlan(String id) async {
    final db = await _database;
    await db.delete('workout_plans', where: 'id = ?', whereArgs: [id]);
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

  Future<List<int>> _getPlanDays(DatabaseExecutor db, String planId) async {
    final maps = await db.query(
      'workout_plan_days',
      where: 'plan_id = ?',
      whereArgs: [planId],
      orderBy: 'day_of_week ASC',
    );
    return maps.map((m) => m['day_of_week'] as int).toList();
  }

  Future<List<PlanExercise>> _getPlanExercises(DatabaseExecutor db, String planId) async {
    final maps = await db.query(
      'plan_exercises',
      where: 'plan_id = ?',
      whereArgs: [planId],
      orderBy: 'sort_order ASC',
    );
    return maps.map(PlanExercise.fromMap).toList();
  }
}
