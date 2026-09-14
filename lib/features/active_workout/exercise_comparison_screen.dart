import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/models/workout_session.dart';
import '../../services/comparison_engine.dart';

class ExerciseComparisonScreen extends StatefulWidget {
  const ExerciseComparisonScreen({
    required this.currentLog,
    this.previousLog,
    super.key,
  });

  final ExerciseLog currentLog;
  final ExerciseLog? previousLog;

  @override
  State<ExerciseComparisonScreen> createState() => _ExerciseComparisonScreenState();
}

class _ExerciseComparisonScreenState extends State<ExerciseComparisonScreen> {
  int _selectedMetric = 0; // 0: Weight, 1: Reps, 2: Volume
  final _comparisonEngine = const ComparisonEngine();

  @override
  Widget build(BuildContext context) {
    final comparison = _comparisonEngine.compareExercise(
      current: widget.currentLog,
      previous: widget.previousLog,
    );

    PerformanceDelta activeDelta;
    switch (_selectedMetric) {
      case 0:
        activeDelta = comparison.weightDelta;
        break;
      case 1:
        activeDelta = comparison.repsDelta;
        break;
      default:
        activeDelta = comparison.volumeDelta;
        break;
    }

    final isImprovement = activeDelta.trend == ComparisonTrend.improvement;
    final isDecline = activeDelta.trend == ComparisonTrend.decline;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Comparison'),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.liquidBackgroundGradient,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.currentLog.exerciseName,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Previous vs Current Performance',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  // Previous vs Current Cards
                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Previous', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                              const SizedBox(height: 8),
                              Text(
                                widget.previousLog == null
                                    ? 'No data'
                                    : '${widget.previousLog!.maxWeight.toStringAsFixed(0)} kg × ${widget.previousLog!.totalReps}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.previousLog == null
                                    ? 'First time logging'
                                    : '${widget.previousLog!.totalVolume.toStringAsFixed(0)} kg vol',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          borderColor: AppColors.primaryLight.withValues(alpha: 0.3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Current', style: TextStyle(color: AppColors.primaryLight, fontSize: 12)),
                              const SizedBox(height: 8),
                              Text(
                                '${widget.currentLog.maxWeight.toStringAsFixed(0)} kg × ${widget.currentLog.totalReps}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.currentLog.totalVolume.toStringAsFixed(0)} kg vol',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Improvement Delta Card
                  GlassCard(
                    padding: const EdgeInsets.all(22),
                    borderColor: isImprovement
                        ? AppColors.accentGreen.withValues(alpha: 0.4)
                        : (isDecline ? AppColors.accentRose.withValues(alpha: 0.4) : AppColors.borderGlass),
                    gradient: LinearGradient(
                      colors: [
                        (isImprovement
                                ? AppColors.accentGreen
                                : (isDecline ? AppColors.accentRose : AppColors.primary))
                            .withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (isImprovement
                                    ? AppColors.accentGreen
                                    : (isDecline ? AppColors.accentRose : Colors.white24))
                                .withValues(alpha: 0.2),
                          ),
                          child: Icon(
                            isImprovement
                                ? Icons.arrow_upward_rounded
                                : (isDecline ? Icons.arrow_downward_rounded : Icons.remove_rounded),
                            color: isImprovement
                                ? AppColors.accentGreen
                                : (isDecline ? AppColors.accentRose : Colors.white70),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeDelta.formattedDifference,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: isImprovement
                                      ? AppColors.accentGreen
                                      : (isDecline ? AppColors.accentRose : Colors.white),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                comparison.hasPrevious
                                    ? '${activeDelta.formattedPercentage} compared to previous'
                                    : 'Baseline performance established',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Metric Selector Pills (Weight, Reps, Volume)
                  Row(
                    children: [
                      _metricTab(0, 'Weight'),
                      const SizedBox(width: 8),
                      _metricTab(1, 'Reps'),
                      const SizedBox(width: 8),
                      _metricTab(2, 'Volume'),
                    ],
                  ),

                  const Spacer(),
                  GlassButton(
                    label: 'Close Comparison',
                    variant: GlassButtonVariant.secondary,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricTab(int index, String label) {
    final isSelected = _selectedMetric == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMetric = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.25) : AppColors.surfaceGlass,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primaryLight : AppColors.borderGlass,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
