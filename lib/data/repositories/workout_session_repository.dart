import 'package:mongo_dart/mongo_dart.dart';
import '../database/mongo_database.dart';
import '../models/workout_session.dart';

class WorkoutSessionRepository {
  WorkoutSessionRepository([MongoDatabase? db]) : _db = db ?? MongoDatabase.instance;
  final MongoDatabase _db;

  Future<WorkoutSession?> getActiveSession() async {
    try {
      final collection = await _db.sessionsCollection;
      final doc = await collection.findOne(
        where.eq('status', WorkoutStatus.inProgress.name).sortBy('started_at', descending: true),
      );
      if (doc == null) return null;
      return _parseSession(doc);
    } catch (_) {
      return null;
    }
  }

  Future<WorkoutSession?> getSessionById(String id) async {
    final collection = await _db.sessionsCollection;
    final doc = await collection.findOne(where.eq('id', id));
    if (doc == null) return null;
    return _parseSession(doc);
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
    final collection = await _db.sessionsCollection;
    final selector = where.eq('status', WorkoutStatus.completed.name).sortBy('started_at', descending: true);

    if (planId != null && planId.isNotEmpty) {
      selector.eq('plan_id', planId);
    }
    if (startDate != null) {
      selector.gte('started_at', startDate.toIso8601String());
    }
    if (endDate != null) {
      selector.lte('started_at', endDate.toIso8601String());
    }
    if (limit != null) {
      selector.limit(limit);
    }
    if (offset != null) {
      selector.skip(offset);
    }

    final docs = await collection.find(selector).toList();
    var sessions = docs.map(_parseSession).toList();

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      sessions = sessions.where((s) => s.planName.toLowerCase().contains(q) || s.note.toLowerCase().contains(q)).toList();
    }

    if (exerciseId != null && exerciseId.isNotEmpty) {
      sessions = sessions.where((s) => s.logs.any((l) => l.exerciseId == exerciseId)).toList();
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
    final collection = await _db.sessionsCollection;
    final doc = session.toMap()
      ..['_id'] = session.id
      ..['logs'] = session.logs.map((log) {
        return log.toMap()..['sets'] = log.sets.map((s) => s.toMap()).toList();
      }).toList();

    await collection.replaceOne(
      where.eq('id', session.id),
      doc,
      upsert: true,
    );
  }

  Future<void> deleteSession(String id) async {
    final collection = await _db.sessionsCollection;
    await collection.deleteOne(where.eq('id', id));
  }

  WorkoutSession _parseSession(Map<String, dynamic> doc) {
    final rawLogs = doc['logs'] as List? ?? [];
    final logs = rawLogs.map((l) {
      final lMap = Map<String, dynamic>.from(l as Map);
      final rawSets = lMap['sets'] as List? ?? [];
      final sets = rawSets.map((s) => SetLog.fromMap(Map<String, dynamic>.from(s as Map))).toList();
      return ExerciseLog.fromMap(lMap, sets: sets);
    }).toList();

    return WorkoutSession.fromMap(doc, logs: logs);
  }
}
