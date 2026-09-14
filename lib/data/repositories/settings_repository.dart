import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/app_settings.dart';

class SettingsRepository {
  SettingsRepository([Database? db]) : _db = db;
  final Database? _db;

  Future<Database> get _database async => _db ?? await AppDatabase.instance.database;

  Future<AppSettings> getSettings() async {
    final db = await _database;
    final maps = await db.query('app_settings', limit: 1);
    if (maps.isEmpty) return const AppSettings();
    return AppSettings.fromMap(maps.first);
  }

  Future<void> saveSettings(AppSettings settings) async {
    final db = await _database;
    await db.insert(
      'app_settings',
      settings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String> exportAllDataAsJson() async {
    final db = await _database;
    final userProfile = await db.query('user_profile');
    final exercises = await db.query('exercises');
    final plans = await db.query('workout_plans');
    final planDays = await db.query('workout_plan_days');
    final planExercises = await db.query('plan_exercises');
    final sessions = await db.query('workout_sessions');
    final exerciseLogs = await db.query('exercise_logs');
    final setLogs = await db.query('set_logs');
    final prs = await db.query('personal_records');
    final settings = await db.query('app_settings');

    final exportMap = {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'user_profile': userProfile,
      'exercises': exercises,
      'workout_plans': plans,
      'workout_plan_days': planDays,
      'plan_exercises': planExercises,
      'workout_sessions': sessions,
      'exercise_logs': exerciseLogs,
      'set_logs': setLogs,
      'personal_records': prs,
      'app_settings': settings,
    };

    return jsonEncode(exportMap);
  }

  Future<bool> importDataFromJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final db = await _database;

      await db.transaction((txn) async {
        if (data['exercises'] is List) {
          for (final row in data['exercises'] as List) {
            await txn.insert('exercises', row as Map<String, dynamic>, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
        if (data['workout_plans'] is List) {
          for (final row in data['workout_plans'] as List) {
            await txn.insert('workout_plans', row as Map<String, dynamic>, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
        if (data['workout_plan_days'] is List) {
          for (final row in data['workout_plan_days'] as List) {
            await txn.insert('workout_plan_days', row as Map<String, dynamic>, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
        if (data['plan_exercises'] is List) {
          for (final row in data['plan_exercises'] as List) {
            await txn.insert('plan_exercises', row as Map<String, dynamic>, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
        if (data['workout_sessions'] is List) {
          for (final row in data['workout_sessions'] as List) {
            await txn.insert('workout_sessions', row as Map<String, dynamic>, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
        if (data['exercise_logs'] is List) {
          for (final row in data['exercise_logs'] as List) {
            await txn.insert('exercise_logs', row as Map<String, dynamic>, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
        if (data['set_logs'] is List) {
          for (final row in data['set_logs'] as List) {
            await txn.insert('set_logs', row as Map<String, dynamic>, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
        if (data['personal_records'] is List) {
          for (final row in data['personal_records'] as List) {
            await txn.insert('personal_records', row as Map<String, dynamic>, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteAllData() async {
    await AppDatabase.instance.clearAllData();
  }
}
