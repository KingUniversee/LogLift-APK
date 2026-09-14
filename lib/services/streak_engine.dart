import '../data/models/workout_session.dart';

class StreakResult {
  const StreakResult({
    required this.currentStreak,
    required this.longestStreak,
  });

  final int currentStreak;
  final int longestStreak;
}

class StreakEngine {
  const StreakEngine();

  StreakResult calculateStreaks(List<WorkoutSession> sessions, {DateTime? now}) {
    final referenceDate = now ?? DateTime.now();
    final today = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);

    // Filter only completed workouts on or before today
    final completed = sessions.where((s) {
      if (s.status != WorkoutStatus.completed) return false;
      final sessionDate = DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day);
      return !sessionDate.isAfter(today);
    }).toList();

    if (completed.isEmpty) {
      return const StreakResult(currentStreak: 0, longestStreak: 0);
    }

    // Unique workout dates sorted ascending
    final uniqueDates = completed
        .map((s) => DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day))
        .toSet()
        .toList()
      ..sort();

    // 1. Calculate longest streak
    var maxStreak = 0;
    var currentChain = 0;
    DateTime? lastDate;

    for (final date in uniqueDates) {
      if (lastDate == null) {
        currentChain = 1;
      } else {
        final diff = date.difference(lastDate).inDays;
        if (diff == 1) {
          currentChain++;
        } else if (diff > 1) {
          currentChain = 1;
        }
      }
      if (currentChain > maxStreak) {
        maxStreak = currentChain;
      }
      lastDate = date;
    }

    // 2. Calculate current streak working backwards from today or yesterday
    var streak = 0;
    var cursor = today;

    // If no workout today, check if yesterday had a workout to keep streak alive
    final hasWorkoutToday = uniqueDates.contains(today);
    final yesterday = today.subtract(const Duration(days: 1));
    final hasWorkoutYesterday = uniqueDates.contains(yesterday);

    if (!hasWorkoutToday && !hasWorkoutYesterday) {
      // Streak broken
      streak = 0;
    } else {
      cursor = hasWorkoutToday ? today : yesterday;
      for (var i = uniqueDates.length - 1; i >= 0; i--) {
        if (uniqueDates.contains(cursor)) {
          streak++;
          cursor = cursor.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
    }

    return StreakResult(
      currentStreak: streak,
      longestStreak: maxStreak,
    );
  }
}
