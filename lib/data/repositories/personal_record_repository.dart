import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/personal_record.dart';

class PersonalRecordRepository {
  PersonalRecordRepository([Database? db]) : _db = db;
  final Database? _db;

  Future<Database> get _database async => _db ?? await AppDatabase.instance.database;

  Future<List<PersonalRecord>> getAllPRs() async {
    final db = await _database;
    final maps = await db.query(
      'personal_records',
      orderBy: 'achieved_at DESC',
    );
    return maps.map(PersonalRecord.fromMap).toList();
  }

  Future<List<PersonalRecord>> getPRsForExercise(String exerciseId) async {
    final db = await _database;
    final maps = await db.query(
      'personal_records',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'achieved_at DESC',
    );
    return maps.map(PersonalRecord.fromMap).toList();
  }

  Future<PersonalRecord?> getBestRecord(String exerciseId, PRType recordType) async {
    final db = await _database;
    final maps = await db.query(
      'personal_records',
      where: 'exercise_id = ? AND record_type = ?',
      whereArgs: [exerciseId, recordType.name],
      orderBy: 'value DESC, achieved_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return PersonalRecord.fromMap(maps.first);
  }

  Future<void> savePR(PersonalRecord pr) async {
    final db = await _database;
    await db.insert(
      'personal_records',
      pr.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deletePRsForSession(String sessionId) async {
    final db = await _database;
    await db.delete(
      'personal_records',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }
}
