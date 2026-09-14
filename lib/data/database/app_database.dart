import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _database;
  bool _isFfiInitialized = false;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Support for unit tests with isolated in-memory databases
  static Future<Database> createInMemory() async {
    sqfliteFfiInit();
    final factory = databaseFactoryFfi;
    final db = await factory.openDatabase(inMemoryDatabasePath);
    await _createTables(db, 1);
    return db;
  }

  Future<Database> _initDatabase() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      if (!_isFfiInitialized) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        _isFfiInitialized = true;
      }
    }

    String path;
    if (kIsWeb) {
      path = 'workout_log.db';
    } else {
      final docDir = await getApplicationDocumentsDirectory();
      path = join(docDir.path, 'workout_log_v1.db');
    }

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _createTables(Database db, int version) async {
    await db.transaction((txn) async {
      // 1. User profile
      await txn.execute('''
        CREATE TABLE user_profile (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          email TEXT NOT NULL,
          avatar_url TEXT,
          fitness_goal TEXT,
          created_at TEXT NOT NULL
        );
      ''');

      // 2. Exercises (No sample data populated - strictly empty until user adds)
      await txn.execute('''
        CREATE TABLE exercises (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          muscle_group TEXT NOT NULL,
          equipment TEXT NOT NULL,
          exercise_type TEXT NOT NULL,
          instructions TEXT,
          notes TEXT,
          is_custom INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL
        );
      ''');

      // 3. Workout plans
      await txn.execute('''
        CREATE TABLE workout_plans (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          color_index INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        );
      ''');

      // 4. Workout plan scheduled days (0=Monday, 6=Sunday)
      await txn.execute('''
        CREATE TABLE workout_plan_days (
          id TEXT PRIMARY KEY,
          plan_id TEXT NOT NULL,
          day_of_week INTEGER NOT NULL,
          FOREIGN KEY (plan_id) REFERENCES workout_plans (id) ON DELETE CASCADE
        );
      ''');

      // 5. Plan exercises
      await txn.execute('''
        CREATE TABLE plan_exercises (
          id TEXT PRIMARY KEY,
          plan_id TEXT NOT NULL,
          exercise_id TEXT NOT NULL,
          exercise_name TEXT NOT NULL,
          exercise_muscle TEXT NOT NULL,
          exercise_type TEXT NOT NULL,
          sort_order INTEGER NOT NULL DEFAULT 0,
          target_sets INTEGER NOT NULL DEFAULT 3,
          target_reps INTEGER NOT NULL DEFAULT 10,
          target_weight REAL NOT NULL DEFAULT 0.0,
          target_duration_seconds INTEGER NOT NULL DEFAULT 0,
          rest_seconds INTEGER NOT NULL DEFAULT 60,
          FOREIGN KEY (plan_id) REFERENCES workout_plans (id) ON DELETE CASCADE
        );
      ''');

      // 6. Workout sessions
      await txn.execute('''
        CREATE TABLE workout_sessions (
          id TEXT PRIMARY KEY,
          plan_id TEXT,
          plan_name TEXT NOT NULL,
          started_at TEXT NOT NULL,
          completed_at TEXT,
          duration_seconds INTEGER NOT NULL DEFAULT 0,
          status TEXT NOT NULL,
          note TEXT
        );
      ''');

      // 7. Exercise logs inside sessions
      await txn.execute('''
        CREATE TABLE exercise_logs (
          id TEXT PRIMARY KEY,
          session_id TEXT NOT NULL,
          exercise_id TEXT NOT NULL,
          exercise_name TEXT NOT NULL,
          exercise_type TEXT NOT NULL,
          sort_order INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (session_id) REFERENCES workout_sessions (id) ON DELETE CASCADE
        );
      ''');

      // 8. Set logs
      await txn.execute('''
        CREATE TABLE set_logs (
          id TEXT PRIMARY KEY,
          exercise_log_id TEXT NOT NULL,
          set_number INTEGER NOT NULL,
          weight_kg REAL NOT NULL DEFAULT 0.0,
          reps INTEGER NOT NULL DEFAULT 0,
          duration_seconds INTEGER NOT NULL DEFAULT 0,
          distance_km REAL NOT NULL DEFAULT 0.0,
          completed INTEGER NOT NULL DEFAULT 1,
          notes TEXT,
          FOREIGN KEY (exercise_log_id) REFERENCES exercise_logs (id) ON DELETE CASCADE
        );
      ''');

      // 9. Personal records
      await txn.execute('''
        CREATE TABLE personal_records (
          id TEXT PRIMARY KEY,
          exercise_id TEXT NOT NULL,
          exercise_name TEXT NOT NULL,
          record_type TEXT NOT NULL,
          value REAL NOT NULL,
          session_id TEXT NOT NULL,
          achieved_at TEXT NOT NULL
        );
      ''');

      // 10. App settings
      await txn.execute('''
        CREATE TABLE app_settings (
          id TEXT PRIMARY KEY,
          appearance TEXT NOT NULL DEFAULT 'dark',
          weight_unit TEXT NOT NULL DEFAULT 'kg',
          distance_unit TEXT NOT NULL DEFAULT 'km',
          default_rest_seconds INTEGER NOT NULL DEFAULT 60,
          notifications_enabled INTEGER NOT NULL DEFAULT 1,
          reminders_enabled INTEGER NOT NULL DEFAULT 1
        );
      ''');

      // Indexes for high performance queries
      await txn.execute('CREATE INDEX idx_sessions_started_at ON workout_sessions(started_at);');
      await txn.execute('CREATE INDEX idx_exercise_logs_session ON exercise_logs(session_id);');
      await txn.execute('CREATE INDEX idx_set_logs_exercise_log ON set_logs(exercise_log_id);');
      await txn.execute('CREATE INDEX idx_plan_exercises_plan ON plan_exercises(plan_id);');
      await txn.execute('CREATE INDEX idx_prs_exercise ON personal_records(exercise_id);');
    });
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration handling
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('set_logs');
      await txn.delete('exercise_logs');
      await txn.delete('personal_records');
      await txn.delete('workout_sessions');
      await txn.delete('plan_exercises');
      await txn.delete('workout_plan_days');
      await txn.delete('workout_plans');
      await txn.delete('exercises');
      await txn.delete('user_profile');
      await txn.delete('app_settings');
    });
  }
}
