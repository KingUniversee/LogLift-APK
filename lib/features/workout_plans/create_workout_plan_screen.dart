import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_text_field.dart';
import '../../data/models/exercise.dart';
import '../../data/models/workout_plan.dart';
import '../../providers/app_providers.dart';
import '../exercises/exercise_library_screen.dart';

class CreateWorkoutPlanScreen extends ConsumerStatefulWidget {
  const CreateWorkoutPlanScreen({this.existingPlan, super.key});

  final WorkoutPlan? existingPlan;

  @override
  ConsumerState<CreateWorkoutPlanScreen> createState() => _CreateWorkoutPlanScreenState();
}

class _CreateWorkoutPlanScreenState extends ConsumerState<CreateWorkoutPlanScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late List<int> _selectedDays;
  late List<PlanExercise> _exercises;
  final _formKey = GlobalKey<FormState>();

  final _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingPlan?.name ?? '');
    _descriptionController = TextEditingController(text: widget.existingPlan?.description ?? '');
    _selectedDays = List<int>.from(widget.existingPlan?.daysOfWeek ?? [0, 2, 4]); // Mon, Wed, Fri by default
    _exercises = List<PlanExercise>.from(widget.existingPlan?.exercises ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _toggleDay(int dayIndex) {
    setState(() {
      if (_selectedDays.contains(dayIndex)) {
        _selectedDays.remove(dayIndex);
      } else {
        _selectedDays.add(dayIndex);
        _selectedDays.sort();
      }
    });
  }

  Future<void> _openAddExercise() async {
    final selectedExercise = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (_) => const ExerciseLibraryScreen(isPickerMode: true),
      ),
    );

    if (selectedExercise != null) {
      final planEx = PlanExercise(
        id: const Uuid().v4(),
        planId: widget.existingPlan?.id ?? 'temp',
        exerciseId: selectedExercise.id,
        exerciseName: selectedExercise.name,
        exerciseMuscle: selectedExercise.muscleGroup,
        exerciseType: selectedExercise.exerciseType,
        sortOrder: _exercises.length,
        targetSets: 3,
        targetReps: 10,
        targetWeight: 0,
        restSeconds: 60,
      );
      setState(() {
        _exercises.add(planEx);
      });
    }
  }

  Future<void> _savePlan() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a plan name')),
      );
      return;
    }

    final planId = widget.existingPlan?.id ?? const Uuid().v4();
    final now = DateTime.now();

    final remappedExercises = _exercises.asMap().entries.map((e) {
      return e.value.copyWith(
        planId: planId,
        sortOrder: e.key,
      );
    }).toList();

    final plan = WorkoutPlan(
      id: planId,
      name: name,
      description: _descriptionController.text.trim(),
      colorIndex: widget.existingPlan?.colorIndex ?? 0,
      createdAt: widget.existingPlan?.createdAt ?? now,
      updatedAt: now,
      daysOfWeek: _selectedDays,
      exercises: remappedExercises,
    );

    await ref.read(workoutPlansProvider.notifier).savePlan(plan);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingPlan != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Workout Plan' : 'Add Workout Plan'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _savePlan,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
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
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                children: [
                  GlassTextField(
                    controller: _nameController,
                    label: 'Plan Name',
                    hint: 'e.g. Strength Training',
                    autofocus: !isEditing,
                  ),
                  const SizedBox(height: 16),

                  GlassTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Brief description...',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // Workout Days Section
                  const Text(
                    'Workout Days',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) {
                      final isSelected = _selectedDays.contains(i);
                      return GestureDetector(
                        onTap: () => _toggleDay(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? AppColors.primary : AppColors.surfaceGlass,
                            border: Border.all(
                              color: isSelected ? AppColors.primaryLight : AppColors.borderGlass,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _dayNames[i],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? Colors.white : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),

                  // Exercises Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Exercises (${_exercises.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _openAddExercise,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Exercise'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (_exercises.isEmpty)
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(Icons.fitness_center_rounded, size: 36, color: AppColors.textMuted),
                          const SizedBox(height: 10),
                          const Text(
                            'No exercises added yet',
                            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          GlassButton(
                            label: 'Add Exercise',
                            icon: Icons.add_rounded,
                            variant: GlassButtonVariant.secondary,
                            height: 44,
                            onPressed: _openAddExercise,
                          ),
                        ],
                      ),
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _exercises.length,
                      // ignore: deprecated_member_use
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex--;
                          final item = _exercises.removeAt(oldIndex);
                          _exercises.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final ex = _exercises[index];
                        return _buildExerciseTile(ex, index);
                      },
                    ),

                  const SizedBox(height: 32),
                  GlassButton(
                    label: isEditing ? 'Update Plan' : 'Save Plan',
                    icon: Icons.check_rounded,
                    onPressed: _savePlan,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseTile(PlanExercise ex, int index) {
    return Padding(
      key: ValueKey(ex.id),
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.drag_handle_rounded, color: AppColors.textMuted, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ex.exerciseName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white),
                      ),
                      Text(
                        '${ex.exerciseMuscle.displayName} · ${ex.exerciseType.displayName}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.accentRose, size: 20),
                  onPressed: () {
                    setState(() {
                      _exercises.removeAt(index);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _selectorRow(
                    label: 'Sets',
                    value: '${ex.targetSets}',
                    onDecrement: () {
                      if (ex.targetSets > 1) {
                        setState(() {
                          _exercises[index] = ex.copyWith(targetSets: ex.targetSets - 1);
                        });
                      }
                    },
                    onIncrement: () {
                      setState(() {
                        _exercises[index] = ex.copyWith(targetSets: ex.targetSets + 1);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _selectorRow(
                    label: 'Reps',
                    value: '${ex.targetReps}',
                    onDecrement: () {
                      if (ex.targetReps > 1) {
                        setState(() {
                          _exercises[index] = ex.copyWith(targetReps: ex.targetReps - 1);
                        });
                      }
                    },
                    onIncrement: () {
                      setState(() {
                        _exercises[index] = ex.copyWith(targetReps: ex.targetReps + 1);
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectorRow({
    required String label,
    required String value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGlass),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          Row(
            children: [
              GestureDetector(
                onTap: onDecrement,
                child: const Icon(Icons.remove_circle_outline_rounded, size: 18, color: AppColors.textSecondary),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
              GestureDetector(
                onTap: onIncrement,
                child: const Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.primaryLight),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
