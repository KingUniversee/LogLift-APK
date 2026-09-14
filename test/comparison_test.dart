import 'package:flutter_test/flutter_test.dart';
import 'package:liftlog/data/models/exercise.dart';
import 'package:liftlog/data/models/workout_session.dart';
import 'package:liftlog/services/comparison_engine.dart';

void main() {
  const engine = ComparisonEngine();

  test('compares exercise performance between previous and current sessions', () {
    final previousLog = ExerciseLog(
      id: 'prev',
      sessionId: 's1',
      exerciseId: 'bench',
      exerciseName: 'Bench Press',
      exerciseType: ExerciseType.strength,
      sortOrder: 0,
      sets: const [
        SetLog(id: 'p1', exerciseLogId: 'prev', setNumber: 1, weightKg: 60, reps: 8, completed: true),
        SetLog(id: 'p2', exerciseLogId: 'prev', setNumber: 2, weightKg: 60, reps: 8, completed: true),
      ],
    );

    final currentLog = ExerciseLog(
      id: 'curr',
      sessionId: 's2',
      exerciseId: 'bench',
      exerciseName: 'Bench Press',
      exerciseType: ExerciseType.strength,
      sortOrder: 0,
      sets: const [
        SetLog(id: 'c1', exerciseLogId: 'curr', setNumber: 1, weightKg: 65, reps: 8, completed: true),
        SetLog(id: 'c2', exerciseLogId: 'curr', setNumber: 2, weightKg: 65, reps: 8, completed: true),
      ],
    );

    final result = engine.compareExercise(current: currentLog, previous: previousLog);

    expect(result.hasPrevious, true);
    expect(result.weightDelta.difference, 5.0);
    expect(result.weightDelta.percentageDifference, closeTo(8.33, 0.01));
    expect(result.weightDelta.trend, ComparisonTrend.improvement);
    expect(result.volumeDelta.difference, 80.0); // 1040 vs 960
  });

  test('handles exercise without previous data gracefully', () {
    final currentLog = ExerciseLog(
      id: 'curr',
      sessionId: 's2',
      exerciseId: 'squat',
      exerciseName: 'Squat',
      exerciseType: ExerciseType.strength,
      sortOrder: 0,
      sets: const [
        SetLog(id: 'c1', exerciseLogId: 'curr', setNumber: 1, weightKg: 100, reps: 5, completed: true),
      ],
    );

    final result = engine.compareExercise(current: currentLog, previous: null);
    expect(result.hasPrevious, false);
    expect(result.weightDelta.difference, 100.0);
  });
}
