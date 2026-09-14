import 'package:flutter_test/flutter_test.dart';
import 'package:liftlog/models.dart';
import 'package:liftlog/stats.dart';

void main() {
  test('calculates completed volume and set totals', () {
    final session = WorkoutSession(
      id: 'one',
      planName: 'Push Day',
      startedAt: DateTime(2026, 9, 14),
      durationMinutes: 45,
      logs: [
        const ExerciseLog(exerciseId: 'bench', sets: [SetLog(reps: 8, weight: 60), SetLog(reps: 8, weight: 65, completed: false)]),
      ],
    );

    final stats = calculateStats([session], now: DateTime(2026, 9, 14));

    expect(stats.workouts, 1);
    expect(stats.sets, 1);
    expect(stats.reps, 8);
    expect(stats.volume, 480);
    expect(stats.streak, 1);
  });

  test('calculates percentage progress', () {
    expect(progressPercent(65, 60), closeTo(8.333, 0.01));
    expect(progressPercent(20, 0), 0);
  });
}