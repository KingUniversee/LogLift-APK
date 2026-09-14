import 'package:intl/intl.dart';
import '../data/models/exercise.dart';
import '../data/models/personal_record.dart';
import '../data/models/workout_session.dart';

enum ReportPeriod { daily, weekly, monthly, yearly }

class ReportData {
  const ReportData({
    required this.period,
    required this.title,
    required this.dateRangeLabel,
    required this.startDate,
    required this.endDate,
    required this.workoutCount,
    required this.durationMinutes,
    required this.sets,
    required this.reps,
    required this.volume,
    required this.exercisesCount,
    required this.sessions,
    required this.prs,
    required this.muscleDistribution,
    required this.previousPeriodVolume,
    required this.monthlyBreakdown,
  });

  final ReportPeriod period;
  final String title;
  final String dateRangeLabel;
  final DateTime startDate;
  final DateTime endDate;
  final int workoutCount;
  final int durationMinutes;
  final int sets;
  final int reps;
  final double volume;
  final int exercisesCount;
  final List<WorkoutSession> sessions;
  final List<PersonalRecord> prs;
  final Map<MuscleGroup, double> muscleDistribution;
  final double previousPeriodVolume;
  final List<double> monthlyBreakdown; // 12 months for yearly report

  double get volumeChangePercent {
    if (previousPeriodVolume == 0) return 0;
    return ((volume - previousPeriodVolume) / previousPeriodVolume) * 100;
  }
}

class ReportService {
  const ReportService();

  ReportData generateReport({
    required ReportPeriod period,
    required DateTime targetDate,
    required List<WorkoutSession> allSessions,
    required List<PersonalRecord> allPrs,
    List<Exercise> allExercises = const [],
  }) {
    DateTime start;
    DateTime end;
    DateTime prevStart;
    DateTime prevEnd;
    String title;
    String dateRangeLabel;

    switch (period) {
      case ReportPeriod.daily:
        start = DateTime(targetDate.year, targetDate.month, targetDate.day, 0, 0, 0);
        end = DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59);
        prevStart = start.subtract(const Duration(days: 1));
        prevEnd = end.subtract(const Duration(days: 1));
        title = 'Daily Report';
        dateRangeLabel = DateFormat('MMMM d, y').format(targetDate);
        break;

      case ReportPeriod.weekly:
        // Week starts Monday (weekday = 1)
        final daysFromMonday = targetDate.weekday - 1;
        start = DateTime(targetDate.year, targetDate.month, targetDate.day - daysFromMonday, 0, 0, 0);
        end = DateTime(start.year, start.month, start.day + 6, 23, 59, 59);
        prevStart = start.subtract(const Duration(days: 7));
        prevEnd = end.subtract(const Duration(days: 7));
        title = 'Weekly Report';
        dateRangeLabel = '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d, y').format(end)}';
        break;

      case ReportPeriod.monthly:
        start = DateTime(targetDate.year, targetDate.month, 1, 0, 0, 0);
        final lastDay = DateTime(targetDate.year, targetDate.month + 1, 0).day;
        end = DateTime(targetDate.year, targetDate.month, lastDay, 23, 59, 59);
        prevStart = DateTime(targetDate.year, targetDate.month - 1, 1, 0, 0, 0);
        final prevLastDay = DateTime(targetDate.year, targetDate.month, 0).day;
        prevEnd = DateTime(targetDate.year, targetDate.month - 1, prevLastDay, 23, 59, 59);
        title = 'Monthly Report';
        dateRangeLabel = DateFormat('MMMM y').format(targetDate);
        break;

      case ReportPeriod.yearly:
        start = DateTime(targetDate.year, 1, 1, 0, 0, 0);
        end = DateTime(targetDate.year, 12, 31, 23, 59, 59);
        prevStart = DateTime(targetDate.year - 1, 1, 1, 0, 0, 0);
        prevEnd = DateTime(targetDate.year - 1, 12, 31, 23, 59, 59);
        title = 'Yearly Report';
        dateRangeLabel = '${targetDate.year}';
        break;
    }

    final periodSessions = allSessions.where((s) {
      return s.status == WorkoutStatus.completed &&
          !s.startedAt.isBefore(start) &&
          !s.startedAt.isAfter(end);
    }).toList();

    final prevPeriodSessions = allSessions.where((s) {
      return s.status == WorkoutStatus.completed &&
          !s.startedAt.isBefore(prevStart) &&
          !s.startedAt.isAfter(prevEnd);
    }).toList();

    final periodPrs = allPrs.where((pr) {
      return !pr.achievedAt.isBefore(start) && !pr.achievedAt.isAfter(end);
    }).toList();

    final workoutCount = periodSessions.length;
    final totalDuration = periodSessions.fold(0, (sum, s) => sum + s.durationSeconds);
    final totalSets = periodSessions.fold(0, (sum, s) => sum + s.completedSets);
    final totalReps = periodSessions.fold(0, (sum, s) => sum + s.totalReps);
    final totalVolume = periodSessions.fold(0.0, (sum, s) => sum + s.totalVolume);
    final prevVolume = prevPeriodSessions.fold(0.0, (sum, s) => sum + s.totalVolume);

    final uniqueExercises = <String>{};
    final muscleCounts = <MuscleGroup, int>{};
    final exerciseMuscleMap = {for (final e in allExercises) e.id: e.muscleGroup};

    for (final s in periodSessions) {
      for (final log in s.logs) {
        uniqueExercises.add(log.exerciseId);
        final muscle = exerciseMuscleMap[log.exerciseId] ?? MuscleGroup.fullBody;
        final completed = log.completedSets;
        if (completed > 0) {
          muscleCounts[muscle] = (muscleCounts[muscle] ?? 0) + completed;
        }
      }
    }

    final muscleDistribution = <MuscleGroup, double>{};
    if (totalSets > 0) {
      for (final entry in muscleCounts.entries) {
        muscleDistribution[entry.key] = (entry.value / totalSets) * 100;
      }
    }

    // Monthly breakdown for yearly reports
    final monthlyBreakdown = List<double>.filled(12, 0.0);
    if (period == ReportPeriod.yearly) {
      for (final s in periodSessions) {
        final monthIdx = s.startedAt.month - 1;
        monthlyBreakdown[monthIdx] += s.totalVolume;
      }
    }

    return ReportData(
      period: period,
      title: title,
      dateRangeLabel: dateRangeLabel,
      startDate: start,
      endDate: end,
      workoutCount: workoutCount,
      durationMinutes: (totalDuration / 60).round(),
      sets: totalSets,
      reps: totalReps,
      volume: totalVolume,
      exercisesCount: uniqueExercises.length,
      sessions: periodSessions,
      prs: periodPrs,
      muscleDistribution: muscleDistribution,
      previousPeriodVolume: prevVolume,
      monthlyBreakdown: monthlyBreakdown,
    );
  }
}
