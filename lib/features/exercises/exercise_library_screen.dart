import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_empty_state.dart';
import '../../core/widgets/glass_text_field.dart';
import '../../data/models/exercise.dart';
import '../../providers/app_providers.dart';
import 'create_exercise_screen.dart';
import 'exercise_details_screen.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({this.isPickerMode = false, super.key});

  final bool isPickerMode;

  @override
  ConsumerState<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final _categories = ['All', 'Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core', 'Cardio'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final query = _searchController.text.trim();
    MuscleGroup? muscle;
    if (_selectedCategory != 'All') {
      muscle = MuscleGroup.fromString(_selectedCategory);
    }
    ref.read(exercisesProvider.notifier).filter(
          query: query.isEmpty ? null : query,
          muscleGroup: muscle,
        );
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isPickerMode ? 'Select Exercise' : 'Exercise Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primaryLight, size: 28),
            tooltip: 'Create Exercise',
            onPressed: () async {
              final newExercise = await Navigator.of(context).push<Exercise>(
                MaterialPageRoute(builder: (_) => const CreateExerciseScreen()),
              );
              if (newExercise != null && widget.isPickerMode && context.mounted) {
                Navigator.of(context).pop(newExercise);
              }
            },
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  // Search field
                  GlassTextField(
                    controller: _searchController,
                    hint: 'Search exercises...',
                    prefixIcon: Icons.search_rounded,
                    onChanged: (_) => _applyFilter(),
                  ),
                  const SizedBox(height: 14),

                  // Horizontal Category Pills
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat;

                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedCategory = cat);
                            _applyFilter();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.surfaceGlass,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppColors.primaryLight : AppColors.borderGlass,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Exercise items list
                  Expanded(
                    child: exercisesAsync.when(
                      data: (exercises) {
                        if (exercises.isEmpty) {
                          return GlassEmptyState(
                            title: 'No exercises yet',
                            message: 'Create your first custom exercise with muscle group and equipment to get started.',
                            icon: Icons.fitness_center_rounded,
                            actionLabel: 'Create Exercise',
                            onAction: () async {
                              final newExercise = await Navigator.of(context).push<Exercise>(
                                MaterialPageRoute(builder: (_) => const CreateExerciseScreen()),
                              );
                              if (newExercise != null && widget.isPickerMode && context.mounted) {
                                Navigator.of(context).pop(newExercise);
                              }
                            },
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.only(bottom: 40),
                          itemCount: exercises.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final exercise = exercises[index];

                            return GlassCard(
                              onTap: () {
                                if (widget.isPickerMode) {
                                  Navigator.of(context).pop(exercise);
                                } else {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ExerciseDetailsScreen(exercise: exercise),
                                    ),
                                  );
                                }
                              },
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
                                          exercise.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${exercise.muscleGroup.displayName} · ${exercise.equipment} · ${exercise.exerciseType.displayName}',
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('Error: $err')),
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
