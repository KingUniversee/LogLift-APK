import 'package:flutter_test/flutter_test.dart';
import 'package:liftlog/data/models/exercise.dart';
import 'package:liftlog/data/models/workout_session.dart';
import 'package:liftlog/services/statistics_service.dart';

void main() {
  const service = StatisticsService();

  test('computes statistics accurately from completed sessions', () {
    final exerciseReal = Exercise(
      id: 'bench',
      name: 'Bench Press',
      muscleGroup: MuscleGroup.chest,
      equipment: 'Barbell',
      exerciseType: ExerciseType.strength,
      createdAt: DateTime(2026, 9, 1),
    );

    final session = WorkoutSession(
      id: 's1',
      planName: 'Push Day',
      startedAt: DateTime(2026, 9, 14, 10),
      durationSeconds: 2700, // 45 min
      status: WorkoutStatus.completed,
      logs: [
        const ExerciseLog(
          id: 'l1',
          sessionId: 's1',
          exerciseId: 'bench',
          exerciseName: 'Bench Press',
          exerciseType: ExerciseType.strength,
          sortOrder: 0,
          sets: [
            SetLog(id: 'set1', exerciseLogId: 'l1', setNumber: 1, weightKg: 60, reps: 8, completed: true),
            SetLog(id: 'set2', exerciseLogId: 'l1', setNumber: 2, weightKg: 65, reps: 8, completed: false), // uncompleted
          ],
        ),
      ],
    );

    final stats = service.computeStats(
      sessions: [session],
      prs: [],
      allExercises: [exerciseReal],
      now: DateTime(2026, 9, 14),
    );

    expect(stats.totalWorkouts, 1);
    expect(stats.totalSets, 1);
    expect(stats.totalReps, 8);
    expect(stats.totalVolume, 480);
    expect(stats.averageVolume, 480);
    expect(stats.totalDurationSeconds, 2700);
    expect(stats.currentStreak, 1);
    expect(stats.muscleDistribution[MuscleGroup.chest], 100.0);
  });

  test('handles empty sessions list with safe zeroes', () {
    final stats = service.computeStats(sessions: [], prs: [], allExercises: []);
    expect(stats.totalWorkouts, 0);
    expect(stats.totalVolume, 0);
    expect(stats.totalSets, 0);
    expect(stats.totalReps, 0);
    expect(stats.muscleDistribution.isEmpty, true);
  });
}