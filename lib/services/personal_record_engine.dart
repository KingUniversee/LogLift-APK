import 'package:uuid/uuid.dart';
import '../data/models/personal_record.dart';
import '../data/models/workout_session.dart';
import '../data/repositories/personal_record_repository.dart';

class PersonalRecordEngine {
  const PersonalRecordEngine(this.repository);
  final PersonalRecordRepository repository;

  Future<List<PersonalRecord>> evaluateAndSaveSessionPRs(WorkoutSession session) async {
    final detectedPRs = <PersonalRecord>[];

    for (final exerciseLog in session.logs) {
      final exerciseId = exerciseLog.exerciseId;
      final exerciseName = exerciseLog.exerciseName;

      // 1. Highest Weight (single set max weight)
      final sessionMaxWeight = exerciseLog.sets
          .where((s) => s.completed)
          .fold(0.0, (max, s) => s.weightKg > max ? s.weightKg : max);

      if (sessionMaxWeight > 0) {
        final existingBest = await repository.getBestRecord(exerciseId, PRType.highestWeight);
        if (existingBest == null || sessionMaxWeight > existingBest.value) {
          final pr = PersonalRecord(
            id: const Uuid().v4(),
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            recordType: PRType.highestWeight,
            value: sessionMaxWeight,
            sessionId: session.id,
            achievedAt: session.completedAt ?? DateTime.now(),
          );
          await repository.savePR(pr);
          detectedPRs.add(pr);
        }
      }

      // 2. Most Reps (single set max reps)
      final sessionMaxReps = exerciseLog.sets
          .where((s) => s.completed)
          .fold(0, (max, s) => s.reps > max ? s.reps : max);

      if (sessionMaxReps > 0) {
        final existingBest = await repository.getBestRecord(exerciseId, PRType.mostReps);
        if (existingBest == null || sessionMaxReps > existingBest.value) {
          final pr = PersonalRecord(
            id: const Uuid().v4(),
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            recordType: PRType.mostReps,
            value: sessionMaxReps.toDouble(),
            sessionId: session.id,
            achievedAt: session.completedAt ?? DateTime.now(),
          );
          await repository.savePR(pr);
          detectedPRs.add(pr);
        }
      }

      // 3. Highest Volume (exercise total volume)
      final sessionTotalVolume = exerciseLog.totalVolume;
      if (sessionTotalVolume > 0) {
        final existingBest = await repository.getBestRecord(exerciseId, PRType.highestVolume);
        if (existingBest == null || sessionTotalVolume > existingBest.value) {
          final pr = PersonalRecord(
            id: const Uuid().v4(),
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            recordType: PRType.highestVolume,
            value: sessionTotalVolume,
            sessionId: session.id,
            achievedAt: session.completedAt ?? DateTime.now(),
          );
          await repository.savePR(pr);
          detectedPRs.add(pr);
        }
      }

      // 4. Longest Duration (single set duration)
      final sessionMaxDuration = exerciseLog.sets
          .where((s) => s.completed)
          .fold(0, (max, s) => s.durationSeconds > max ? s.durationSeconds : max);

      if (sessionMaxDuration > 0) {
        final existingBest = await repository.getBestRecord(exerciseId, PRType.longestDuration);
        if (existingBest == null || sessionMaxDuration > existingBest.value) {
          final pr = PersonalRecord(
            id: const Uuid().v4(),
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            recordType: PRType.longestDuration,
            value: sessionMaxDuration.toDouble(),
            sessionId: session.id,
            achievedAt: session.completedAt ?? DateTime.now(),
          );
          await repository.savePR(pr);
          detectedPRs.add(pr);
        }
      }

      // 5. Longest Distance
      final sessionMaxDistance = exerciseLog.sets
          .where((s) => s.completed)
          .fold(0.0, (max, s) => s.distanceKm > max ? s.distanceKm : max);

      if (sessionMaxDistance > 0) {
        final existingBest = await repository.getBestRecord(exerciseId, PRType.longestDistance);
        if (existingBest == null || sessionMaxDistance > existingBest.value) {
          final pr = PersonalRecord(
            id: const Uuid().v4(),
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            recordType: PRType.longestDistance,
            value: sessionMaxDistance,
            sessionId: session.id,
            achievedAt: session.completedAt ?? DateTime.now(),
          );
          await repository.savePR(pr);
          detectedPRs.add(pr);
        }
      }
    }

    return detectedPRs;
  }
}
