import 'models.dart';

class WorkoutStats {
  const WorkoutStats({
    required this.workouts,
    required this.sets,
    required this.reps,
    required this.volume,
    required this.duration,
    required this.streak,
  });

  final int workouts;
  final int sets;
  final int reps;
  final double volume;
  final int duration;
  final int streak;

  double get averageDuration => workouts == 0 ? 0 : duration / workouts;
}

WorkoutStats calculateStats(List<WorkoutSession> sessions, {DateTime? now}) {
  final completed = sessions.where((session) => session.status == WorkoutStatus.completed).toList();
  final sortedDates = completed.map((session) => DateTime(session.startedAt.year, session.startedAt.month, session.startedAt.day)).toSet().toList()..sort();
  var streak = 0;
  var cursor = DateTime(now?.year ?? DateTime.now().year, now?.month ?? DateTime.now().month, now?.day ?? DateTime.now().day);
  for (var index = sortedDates.length - 1; index >= 0; index--) {
    if (sortedDates[index] == cursor || sortedDates[index] == cursor.subtract(const Duration(days: 1))) {
      streak++;
      cursor = sortedDates[index].subtract(const Duration(days: 1));
    } else {
      break;
    }
  }
  return WorkoutStats(
    workouts: completed.length,
    sets: completed.fold(0, (sum, session) => sum + session.completedSets),
    reps: completed.fold(0, (sum, session) => sum + session.totalReps),
    volume: completed.fold(0, (sum, session) => sum + session.totalVolume),
    duration: completed.fold(0, (sum, session) => sum + session.durationMinutes),
    streak: streak,
  );
}

double progressPercent(double current, double previous) => previous == 0 ? 0 : ((current - previous) / previous) * 100;
