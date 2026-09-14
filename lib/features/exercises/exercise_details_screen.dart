import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/models/exercise.dart';
import '../../providers/app_providers.dart';
import '../workout_plans/create_workout_plan_screen.dart';
import 'create_exercise_screen.dart';

class ExerciseDetailsScreen extends ConsumerWidget {
  const ExerciseDetailsScreen({required this.exercise, super.key});

  final Exercise exercise;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${exercise.name}"?'),
        content: const Text(
          'This removes the exercise from your library. Previous workout logs containing this exercise will remain preserved.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.accentRose),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(exercisesProvider.notifier).deleteExercise(exercise.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CreateExerciseScreen(existingExercise: exercise)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.accentRose),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.liquidBackgroundGradient,
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              children: [
                // Hero Exercise Graphic / Icon Card
                GlassCard(
                  padding: const EdgeInsets.all(32),
                  borderRadius: 28,
                  gradient: AppColors.heroCardGradient,
                  child: Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.2),
                        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        size: 48,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  exercise.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),

                // Tags Row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _tag(exercise.muscleGroup.displayName, AppColors.primary),
                    _tag(exercise.equipment, AppColors.accentPurple),
                    _tag(exercise.exerciseType.displayName, AppColors.accentCyan),
                  ],
                ),
                const SizedBox(height: 24),

                // Instructions Section
                const Text(
                  'Instructions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                GlassCard(
                  child: Text(
                    exercise.instructions.isNotEmpty
                        ? exercise.instructions
                        : 'No specific instructions provided for this exercise.',
                    style: const TextStyle(color: AppColors.textSecondary, height: 1.5, fontSize: 14),
                  ),
                ),

                if (exercise.notes.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Notes & Tips',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GlassCard(
                    child: Text(
                      exercise.notes,
                      style: const TextStyle(color: AppColors.textSecondary, height: 1.4, fontSize: 14),
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Add to Plan Button
                GlassButton(
                  label: 'Add to Plan',
                  icon: Icons.add_rounded,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CreateWorkoutPlanScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
