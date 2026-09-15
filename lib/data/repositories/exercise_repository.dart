import 'package:mongo_dart/mongo_dart.dart';
import '../database/mongo_database.dart';
import '../models/exercise.dart';

class ExerciseRepository {
  ExerciseRepository([MongoDatabase? db]) : _db = db ?? MongoDatabase.instance;
  final MongoDatabase _db;

  Future<List<Exercise>> getExercises({
    String? query,
    MuscleGroup? muscleGroup,
    ExerciseType? exerciseType,
  }) async {
    final collection = await _db.exercisesCollection;
    final selector = where.sortBy('name');

    if (muscleGroup != null) {
      selector.eq('muscle_group', muscleGroup.name);
    }
    if (exerciseType != null) {
      selector.eq('exercise_type', exerciseType.name);
    }

    final docs = await collection.find(selector).toList();

    var exercises = docs.map((doc) => Exercise.fromMap(doc)).toList();

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      exercises = exercises.where((e) {
        return e.name.toLowerCase().contains(q) ||
            e.equipment.toLowerCase().contains(q) ||
            e.instructions.toLowerCase().contains(q);
      }).toList();
    }

    return exercises;
  }

  Future<Exercise?> getExerciseById(String id) async {
    final collection = await _db.exercisesCollection;
    final doc = await collection.findOne(where.eq('id', id));
    if (doc == null) return null;
    return Exercise.fromMap(doc);
  }

  Future<void> saveExercise(Exercise exercise) async {
    final collection = await _db.exercisesCollection;
    final doc = exercise.toMap()..['_id'] = exercise.id;
    await collection.replaceOne(
      where.eq('id', exercise.id),
      doc,
      upsert: true,
    );
  }

  Future<void> deleteExercise(String id) async {
    final collection = await _db.exercisesCollection;
    await collection.deleteOne(where.eq('id', id));
  }
}
