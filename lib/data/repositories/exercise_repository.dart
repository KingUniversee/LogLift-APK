import '../../core/network/api_client.dart';
import '../models/exercise.dart';

class ExerciseRepository {
  ExerciseRepository([ApiClient? api]) : _api = api ?? ApiClient.instance;
  final ApiClient _api;

  Future<List<Exercise>> getExercises({
    String? query,
    MuscleGroup? muscleGroup,
    ExerciseType? exerciseType,
  }) async {
    final queryParams = <String, String>{};
    if (query != null && query.trim().isNotEmpty) {
      queryParams['query'] = query.trim();
    }
    if (muscleGroup != null) {
      queryParams['muscleGroup'] = muscleGroup.name;
    }
    if (exerciseType != null) {
      queryParams['exerciseType'] = exerciseType.name;
    }

    final response = await _api.get(
      '/exercises',
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response is List) {
      return response
          .map((doc) => Exercise.fromMap(Map<String, dynamic>.from(doc as Map)))
          .toList();
    }
    return [];
  }

  Future<Exercise?> getExerciseById(String id) async {
    try {
      final response = await _api.get('/exercises/$id');
      if (response is Map<String, dynamic>) {
        return Exercise.fromMap(response);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveExercise(Exercise exercise) async {
    await _api.post('/exercises', body: exercise.toMap());
  }

  Future<void> deleteExercise(String id) async {
    await _api.delete('/exercises/$id');
  }
}
