import 'package:flutter_test/flutter_test.dart';
import 'package:liftlog/data/models/workout_session.dart';
import 'package:liftlog/services/streak_engine.dart';

void main() {
  const engine = StreakEngine();

  test('calculates streak correctly with consecutive days and yesterday grace', () {
    final base = DateTime(2026, 9, 14);

    final sessions = [
      WorkoutSession(
        id: '1',
        planName: 'Day 1',
        startedAt: DateTime(2026, 9, 14, 10),
        status: WorkoutStatus.completed,
      ),
      WorkoutSession(
        id: '2',
        planName: 'Day 2',
        startedAt: DateTime(2026, 9, 13, 9),
        status: WorkoutStatus.completed,
      ),
      WorkoutSession(
        id: '3',
        planName: 'Day 2 second workout',
        startedAt: DateTime(2026, 9, 13, 17), // Same day multiple workouts
        status: WorkoutStatus.completed,
      ),
      WorkoutSession(
        id: '4',
        planName: 'Day 3',
        startedAt: DateTime(2026, 9, 12, 8),
        status: WorkoutStatus.completed,
      ),
      WorkoutSession(
        id: '5',
        planName: 'Cancelled workout',
        startedAt: DateTime(2026, 9, 11, 8),
        status: WorkoutStatus.cancelled, // Cancelled shouldn't count
      ),
    ];

    final result = engine.calculateStreaks(sessions, now: base);
    expect(result.currentStreak, 3);
    expect(result.longestStreak, 3);
  });

  test('breaks streak when a day is skipped', () {
    final base = DateTime(2026, 9, 14);

    final sessions = [
      WorkoutSession(
        id: '1',
        planName: 'Old 1',
        startedAt: DateTime(2026, 9, 10),
        status: WorkoutStatus.completed,
      ),
      WorkoutSession(
        id: '2',
        planName: 'Old 2',
        startedAt: DateTime(2026, 9, 9),
        status: WorkoutStatus.completed,
      ),
    ];

    final result = engine.calculateStreaks(sessions, now: base);
    expect(result.currentStreak, 0);
    expect(result.longestStreak, 2);
  });
}
