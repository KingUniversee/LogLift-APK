import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/models/workout_plan.dart';
import '../../providers/active_workout_provider.dart';
import 'active_workout_screen.dart';

class StartWorkoutScreen extends ConsumerWidget {
  const StartWorkoutScreen({required this.plan, super.key});

  final WorkoutPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(plan.name),
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
                    plan.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Estimated time: ${plan.estimatedDurationMinutes} min · ${plan.exercises.length} exercises',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // Start Workout Primary Button
                  GlassButton(
                    label: 'Start Workout',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () async {
                      await ref.read(activeWorkoutProvider.notifier).startWorkout(plan: plan);
                      if (context.mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Exercises',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: plan.exercises.isEmpty
                        ? const Center(
                            child: Text(
                              'No exercises configured in this plan.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          )
                        : ListView.separated(
                            itemCount: plan.exercises.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final ex = plan.exercises[index];
                              return GlassCard(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.fitness_center_rounded,
                                        color: AppColors.primaryLight,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ex.exerciseName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${ex.targetSets} sets × ${ex.targetReps} reps',
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${ex.restSeconds}s rest',
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
