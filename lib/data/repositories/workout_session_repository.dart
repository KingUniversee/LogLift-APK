import '../../core/network/api_client.dart';
import '../models/workout_session.dart';

class WorkoutSessionRepository {
  WorkoutSessionRepository([ApiClient? api]) : _api = api ?? ApiClient.instance;
  final ApiClient _api;

  Future<WorkoutSession?> getActiveSession() async {
    try {
      final response = await _api.get('/workout-sessions/active');
      if (response is Map<String, dynamic>) {
        return _parseSession(response);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<WorkoutSession?> getSessionById(String id) async {
    try {
      final response = await _api.get('/workout-sessions/$id');
      if (response is Map<String, dynamic>) {
        return _parseSession(response);
      }
      return null;
    } catch (_) {
      return null;
    }
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
    final queryParams = <String, String>{
      'status': WorkoutStatus.completed.name,
    };

    if (query != null && query.trim().isNotEmpty) {
      queryParams['query'] = query.trim();
    }
    if (planId != null && planId.isNotEmpty) {
      queryParams['planId'] = planId;
    }
    if (exerciseId != null && exerciseId.isNotEmpty) {
      queryParams['exerciseId'] = exerciseId;
    }
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }
    if (limit != null) {
      queryParams['limit'] = limit.toString();
    }
    if (offset != null) {
      queryParams['offset'] = offset.toString();
    }

    final response = await _api.get('/workout-sessions', queryParams: queryParams);

    if (response is List) {
      return response
          .map((doc) => _parseSession(Map<String, dynamic>.from(doc as Map)))
          .toList();
    }
    return [];
  }

  Future<ExerciseLog?> getPreviousExercisePerformance(
    String exerciseId, {
    String? excludeSessionId,
  }) async {
    final sessions = await getCompletedSessions(exerciseId: exerciseId, limit: 10);

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
    final doc = session.toMap()
      ..['id'] = session.id
      ..['logs'] = session.logs.map((log) {
        return log.toMap()..['sets'] = log.sets.map((s) => s.toMap()).toList();
      }).toList();

    await _api.post('/workout-sessions', body: doc);
  }

  Future<void> deleteSession(String id) async {
    await _api.delete('/workout-sessions/$id');
  }

  WorkoutSession _parseSession(Map<String, dynamic> doc) {
    final rawLogs = doc['logs'] as List? ?? [];
    final logs = rawLogs.map((l) {
      final lMap = Map<String, dynamic>.from(l as Map);
      final rawSets = lMap['sets'] as List? ?? [];
      final sets = rawSets
          .map((s) => SetLog.fromMap(Map<String, dynamic>.from(s as Map)))
          .toList();
      return ExerciseLog.fromMap(lMap, sets: sets);
    }).toList();

    return WorkoutSession.fromMap(doc, logs: logs);
  }
}
