import '../data/models/exercise.dart';
import '../data/models/personal_record.dart';
import '../data/models/workout_session.dart';
import 'streak_engine.dart';

class OverallStats {
  const OverallStats({
    required this.totalWorkouts,
    required this.totalVolume,
    required this.totalSets,
    required this.totalReps,
    required this.totalDurationSeconds,
    required this.averageDurationSeconds,
    required this.averageVolume,
    required this.averageSets,
    required this.averageReps,
    required this.currentStreak,
    required this.longestStreak,
    required this.prCount,
    required this.muscleDistribution,
  });

  factory OverallStats.empty() => const OverallStats(
    totalWorkouts: 0,
    totalVolume: 0.0,
    totalSets: 0,
    totalReps: 0,
    totalDurationSeconds: 0,
    averageDurationSeconds: 0.0,
    averageVolume: 0.0,
    averageSets: 0.0,
    averageReps: 0.0,
    currentStreak: 0,
    longestStreak: 0,
    prCount: 0,
    muscleDistribution: {},
  );

  final int totalWorkouts;
  final double totalVolume;
  final int totalSets;
  final int totalReps;
  final int totalDurationSeconds;
  final double averageDurationSeconds;
  final double averageVolume;
  final double averageSets;
  final double averageReps;
  final int currentStreak;
  final int longestStreak;
  final int prCount;
  final Map<MuscleGroup, double> muscleDistribution; // MuscleGroup -> Percentage (0.0 to 100.0)

  int get averageDurationMinutes => (averageDurationSeconds / 60).round();
  int get totalDurationMinutes => (totalDurationSeconds / 60).round();
}

class DailyVolumePoint {
  const DailyVolumePoint({
    required this.date,
    required this.volume,
    required this.sets,
  });

  final DateTime date;
  final double volume;
  final int sets;
}

class StatisticsService {
  const StatisticsService({
    this.streakEngine = const StreakEngine(),
  });

  final StreakEngine streakEngine;

  OverallStats computeStats({
    required List<WorkoutSession> sessions,
    required List<PersonalRecord> prs,
    List<Exercise> allExercises = const [],
    DateTime? now,
  }) {
    final completed = sessions.where((s) => s.status == WorkoutStatus.completed).toList();
    final totalWorkouts = completed.length;

    if (totalWorkouts == 0) {
      return const OverallStats(
        totalWorkouts: 0,
        totalVolume: 0,
        totalSets: 0,
        totalReps: 0,
        totalDurationSeconds: 0,
        averageDurationSeconds: 0,
        averageVolume: 0,
        averageSets: 0,
        averageReps: 0,
        currentStreak: 0,
        longestStreak: 0,
        prCount: 0,
        muscleDistribution: {},
      );
    }

    final totalVolume = completed.fold(0.0, (sum, s) => sum + s.totalVolume);
    final totalSets = completed.fold(0, (sum, s) => sum + s.completedSets);
    final totalReps = completed.fold(0, (sum, s) => sum + s.totalReps);
    final totalDuration = completed.fold(0, (sum, s) => sum + s.durationSeconds);

    final streaks = streakEngine.calculateStreaks(completed, now: now);

    // Calculate muscle group distribution
    final exerciseMuscleMap = {for (final e in allExercises) e.id: e.muscleGroup};
    final muscleCounts = <MuscleGroup, int>{};
    var totalLoggedSets = 0;

    for (final session in completed) {
      for (final log in session.logs) {
        final muscle = exerciseMuscleMap[log.exerciseId] ?? MuscleGroup.fullBody;
        final completedSets = log.completedSets;
        if (completedSets > 0) {
          muscleCounts[muscle] = (muscleCounts[muscle] ?? 0) + completedSets;
          totalLoggedSets += completedSets;
        }
      }
    }

    final muscleDistribution = <MuscleGroup, double>{};
    if (totalLoggedSets > 0) {
      for (final entry in muscleCounts.entries) {
        muscleDistribution[entry.key] = (entry.value / totalLoggedSets) * 100;
      }
    }

    return OverallStats(
      totalWorkouts: totalWorkouts,
      totalVolume: totalVolume,
      totalSets: totalSets,
      totalReps: totalReps,
      totalDurationSeconds: totalDuration,
      averageDurationSeconds: totalDuration / totalWorkouts,
      averageVolume: totalVolume / totalWorkouts,
      averageSets: totalSets / totalWorkouts,
      averageReps: totalReps / totalWorkouts,
      currentStreak: streaks.currentStreak,
      longestStreak: streaks.longestStreak,
      prCount: prs.length,
      muscleDistribution: muscleDistribution,
    );
  }

  List<DailyVolumePoint> aggregateVolumeByDay(
    List<WorkoutSession> sessions, {
    required int days,
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    final startDate = today.subtract(Duration(days: days - 1));

    final map = <DateTime, DailyVolumePoint>{};
    for (var i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      map[date] = DailyVolumePoint(date: date, volume: 0, sets: 0);
    }

    final completed = sessions.where((s) => s.status == WorkoutStatus.completed);
    for (final session in completed) {
      final sDate = DateTime(session.startedAt.year, session.startedAt.month, session.startedAt.day);
      if (map.containsKey(sDate)) {
        final existing = map[sDate]!;
        map[sDate] = DailyVolumePoint(
          date: sDate,
          volume: existing.volume + session.totalVolume,
          sets: existing.sets + session.completedSets,
        );
      }
    }

    final list = map.values.toList()..sort((a, b) => a.date.compareTo(b.date));
    return list;
  }
}
