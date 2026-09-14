import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/workout_session.dart';

class WorkoutSessionRepository {
  WorkoutSessionRepository([Database? db]) : _db = db;
  final Database? _db;

  Future<Database> get _database async => _db ?? await AppDatabase.instance.database;

  Future<WorkoutSession?> getActiveSession() async {
    final db = await _database;
    final maps = await db.query(
      'workout_sessions',
      where: 'status = ?',
      whereArgs: [WorkoutStatus.inProgress.name],
      orderBy: 'started_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return _populateSession(db, maps.first);
  }

  Future<WorkoutSession?> getSessionById(String id) async {
    final db = await _database;
    final maps = await db.query(
      'workout_sessions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return _populateSession(db, maps.first);
  }

  Future<List<WorkoutSession>> getCompletedSessions({
    String? query,
    String? planId,
    String? exerciseId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    final db = await _database;
    final whereClauses = <String>['status = ?'];
    final whereArgs = <dynamic>[WorkoutStatus.completed.name];

    if (query != null && query.trim().isNotEmpty) {
      whereClauses.add('(plan_name LIKE ? OR note LIKE ?)');
      final term = '%${query.trim()}%';
      whereArgs.addAll([term, term]);
    }

    if (planId != null && planId.isNotEmpty) {
      whereClauses.add('plan_id = ?');
      whereArgs.add(planId);
    }

    if (startDate != null) {
      whereClauses.add('started_at >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClauses.add('started_at <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    final whereString = whereClauses.join(' AND ');

    final sessionMaps = await db.query(
      'workout_sessions',
      where: whereString,
      whereArgs: whereArgs,
      orderBy: 'started_at DESC',
      limit: limit,
      offset: offset,
    );

    final sessions = <WorkoutSession>[];
    for (final map in sessionMaps) {
      final session = await _populateSession(db, map);
      // Filter by exercise if requested
      if (exerciseId != null && exerciseId.isNotEmpty) {
        if (!session.logs.any((l) => l.exerciseId == exerciseId)) {
          continue;
        }
      }
      sessions.add(session);
    }
    return sessions;
  }

  Future<ExerciseLog?> getPreviousExercisePerformance(
    String exerciseId, {
    String? excludeSessionId,
  }) async {
    final sessions = await getCompletedSessions();

    for (final session in sessions) {
      if (excludeSessionId != null && session.id == excludeSessionId) continue;
      final match = session.logs.where((l) => l.exerciseId == exerciseId && l.completedSets > 0).toList();
      if (match.isNotEmpty) {
        return match.first;
      }
    }
    return null;
  }

  Future<void> saveSession(WorkoutSession session) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.insert(
        'workout_sessions',
        session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Exercise logs & sets
      // First clear old logs for this session to handle set edits/removals cleanly
      final oldLogs = await txn.query(
        'exercise_logs',
        where: 'session_id = ?',
        whereArgs: [session.id],
      );
      for (final log in oldLogs) {
        await txn.delete('set_logs', where: 'exercise_log_id = ?', whereArgs: [log['id']]);
      }
      await txn.delete('exercise_logs', where: 'session_id = ?', whereArgs: [session.id]);

      // Re-insert logs & sets
      for (var i = 0; i < session.logs.length; i++) {
        final log = session.logs[i].copyWith(sortOrder: i);
        await txn.insert('exercise_logs', log.toMap());

        for (var j = 0; j < log.sets.length; j++) {
          final setLog = log.sets[j].copyWith(
            exerciseLogId: log.id,
            setNumber: j + 1,
          );
          await txn.insert('set_logs', setLog.toMap());
        }
      }
    });
  }

  Future<void> deleteSession(String id) async {
    final db = await _database;
    await db.delete('workout_sessions', where: 'id = ?', whereArgs: [id]);
  }

  Future<WorkoutSession> _populateSession(DatabaseExecutor db, Map<String, dynamic> map) async {
    final sessionId = map['id'] as String;
    final logMaps = await db.query(
      'exercise_logs',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'sort_order ASC',
    );

    final logs = <ExerciseLog>[];
    for (final logMap in logMaps) {
      final logId = logMap['id'] as String;
      final setMaps = await db.query(
        'set_logs',
        where: 'exercise_log_id = ?',
        whereArgs: [logId],
        orderBy: 'set_number ASC',
      );
      final sets = setMaps.map(SetLog.fromMap).toList();
      logs.add(ExerciseLog.fromMap(logMap, sets: sets));
    }

    return WorkoutSession.fromMap(map, logs: logs);
  }
}
