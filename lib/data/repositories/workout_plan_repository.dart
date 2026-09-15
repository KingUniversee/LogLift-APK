import '../../core/network/api_client.dart';
import '../models/workout_plan.dart';

class WorkoutPlanRepository {
  WorkoutPlanRepository([ApiClient? api]) : _api = api ?? ApiClient.instance;
  final ApiClient _api;

  Future<List<WorkoutPlan>> getPlans({String? query}) async {
    final queryParams = <String, String>{};
    if (query != null && query.trim().isNotEmpty) {
      queryParams['query'] = query.trim();
    }

    final response = await _api.get(
      '/workout-plans',
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response is List) {
      return response.map((doc) => _parsePlan(Map<String, dynamic>.from(doc as Map))).toList();
    }
    return [];
  }

  Future<WorkoutPlan?> getPlanById(String id) async {
    try {
      final response = await _api.get('/workout-plans/$id');
      if (response is Map<String, dynamic>) {
        return _parsePlan(response);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<WorkoutPlan?> getTodayPlan(DateTime date) async {
    final all = await getPlans();
    final matches = all.where((p) => p.isScheduledFor(date)).toList();
    if (matches.isEmpty) return null;
    return matches.first;
  }

  Future<void> savePlan(WorkoutPlan plan) async {
    final payload = plan.toMap()
      ..['days_of_week'] = plan.daysOfWeek
      ..['exercises'] = plan.exercises.map((e) => e.toMap()).toList();

    await _api.post('/workout-plans', body: payload);
  }

  Future<void> deletePlan(String id) async {
    await _api.delete('/workout-plans/$id');
  }

  Future<WorkoutPlan?> duplicatePlan(String id) async {
    try {
      final response = await _api.post('/workout-plans/$id/duplicate');
      if (response is Map<String, dynamic>) {
        return _parsePlan(response);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  WorkoutPlan _parsePlan(Map<String, dynamic> doc) {
    final days = List<int>.from(doc['days_of_week'] as List? ?? []);
    final rawExercises = doc['exercises'] as List? ?? [];
    final exercises = rawExercises
        .map((e) => PlanExercise.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    return WorkoutPlan.fromMap(doc, days: days, exercises: exercises);
  }
}
