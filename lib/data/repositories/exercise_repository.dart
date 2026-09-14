import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/exercise.dart';

class ExerciseRepository {
  ExerciseRepository([Database? db]) : _db = db;
  final Database? _db;

  Future<Database> get _database async => _db ?? await AppDatabase.instance.database;

  Future<List<Exercise>> getExercises({
    String? query,
    MuscleGroup? muscleGroup,
    ExerciseType? exerciseType,
  }) async {
    final db = await _database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (query != null && query.trim().isNotEmpty) {
      whereClauses.add('(name LIKE ? OR equipment LIKE ? OR instructions LIKE ?)');
      final term = '%${query.trim()}%';
      whereArgs.addAll([term, term, term]);
    }

    if (muscleGroup != null) {
      whereClauses.add('muscle_group = ?');
      whereArgs.add(muscleGroup.name);
    }

    if (exerciseType != null) {
      whereClauses.add('exercise_type = ?');
      whereArgs.add(exerciseType.name);
    }

    final whereString = whereClauses.isEmpty ? null : whereClauses.join(' AND ');

    final maps = await db.query(
      'exercises',
      where: whereString,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'name ASC',
    );

    return maps.map(Exercise.fromMap).toList();
  }

  Future<Exercise?> getExerciseById(String id) async {
    final db = await _database;
    final maps = await db.query(
      'exercises',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Exercise.fromMap(maps.first);
  }

  Future<void> saveExercise(Exercise exercise) async {
    final db = await _database;
    await db.insert(
      'exercises',
      exercise.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteExercise(String id) async {
    final db = await _database;
    await db.delete(
      'exercises',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
