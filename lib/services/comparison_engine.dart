import '../data/models/workout_session.dart';

enum ComparisonTrend { improvement, decline, same }

class PerformanceDelta {
  const PerformanceDelta({
    required this.metricName,
    required this.previousValue,
    required this.currentValue,
    required this.unit,
  });

  final String metricName;
  final double previousValue;
  final double currentValue;
  final String unit;

  double get difference => currentValue - previousValue;
  
  double get percentageDifference {
    if (previousValue == 0) return 0;
    return ((currentValue - previousValue) / previousValue) * 100;
  }

  ComparisonTrend get trend {
    if (difference > 0.001) return ComparisonTrend.improvement;
    if (difference < -0.001) return ComparisonTrend.decline;
    return ComparisonTrend.same;
  }

  String get formattedDifference {
    final prefix = difference > 0 ? '+' : '';
    return '$prefix${difference.toStringAsFixed(difference.truncateToDouble() == difference ? 0 : 1)} $unit';
  }

  String get formattedPercentage {
    final prefix = percentageDifference > 0 ? '+' : '';
    return '$prefix${percentageDifference.toStringAsFixed(1)}%';
  }
}

class ExerciseComparisonResult {
  const ExerciseComparisonResult({
    required this.exerciseName,
    required this.previousLog,
    required this.currentLog,
    required this.weightDelta,
    required this.repsDelta,
    required this.volumeDelta,
  });

  final String exerciseName;
  final ExerciseLog? previousLog;
  final ExerciseLog currentLog;
  final PerformanceDelta weightDelta;
  final PerformanceDelta repsDelta;
  final PerformanceDelta volumeDelta;

  bool get hasPrevious => previousLog != null;
}

class ComparisonEngine {
  const ComparisonEngine();

  ExerciseComparisonResult compareExercise({
    required ExerciseLog current,
    ExerciseLog? previous,
  }) {
    final prevMaxWeight = previous?.maxWeight ?? 0.0;
    final currMaxWeight = current.maxWeight;

    final prevTotalReps = previous?.totalReps.toDouble() ?? 0.0;
    final currTotalReps = current.totalReps.toDouble();

    final prevTotalVolume = previous?.totalVolume ?? 0.0;
    final currTotalVolume = current.totalVolume;

    return ExerciseComparisonResult(
      exerciseName: current.exerciseName,
      previousLog: previous,
      currentLog: current,
      weightDelta: PerformanceDelta(
        metricName: 'Weight',
        previousValue: prevMaxWeight,
        currentValue: currMaxWeight,
        unit: 'kg',
      ),
      repsDelta: PerformanceDelta(
        metricName: 'Reps',
        previousValue: prevTotalReps,
        currentValue: currTotalReps,
        unit: 'reps',
      ),
      volumeDelta: PerformanceDelta(
        metricName: 'Volume',
        previousValue: prevTotalVolume,
        currentValue: currTotalVolume,
        unit: 'kg',
      ),
    );
  }

  PerformanceDelta compareWorkoutVolume({
    required double currentVolume,
    required double previousVolume,
  }) {
    return PerformanceDelta(
      metricName: 'Total Volume',
      previousValue: previousVolume,
      currentValue: currentVolume,
      unit: 'kg',
    );
  }
}
