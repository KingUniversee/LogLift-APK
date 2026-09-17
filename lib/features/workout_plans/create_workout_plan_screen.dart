import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late Map<int, List<PlanExercise>> _dayExercises;
  int _currentDayIndex = 0;
  final _formKey = GlobalKey<FormState>();

  final _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final _dayFullNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingPlan?.name ?? '');
    _descriptionController = TextEditingController(text: widget.existingPlan?.description ?? '');
    _selectedDays = List<int>.from(widget.existingPlan?.daysOfWeek ?? [0, 2, 4]); // Mon, Wed, Fri by default
    _currentDayIndex = _selectedDays.isNotEmpty ? _selectedDays.first : 0;

    _dayExercises = {for (int i = 0; i < 7; i++) i: <PlanExercise>[]};

    if (widget.existingPlan != null) {
      final existing = widget.existingPlan!;
      final hasDaySpecific = existing.exercises.any((e) => e.dayOfWeek != null);
      if (hasDaySpecific) {
        for (final ex in existing.exercises) {
          if (ex.dayOfWeek != null && ex.dayOfWeek! >= 0 && ex.dayOfWeek! < 7) {
            _dayExercises[ex.dayOfWeek!]!.add(ex);
          }
        }
      } else if (existing.exercises.isNotEmpty) {
        // Legacy plan without day tags: place existing exercises in the primary/first selected day without duplicating across all days
        final primaryDay = _selectedDays.isNotEmpty ? _selectedDays.first : 0;
        _dayExercises[primaryDay] = List<PlanExercise>.from(existing.exercises);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onDayTapped(int dayIndex) {
    setState(() {
      _currentDayIndex = dayIndex;
    });
  }

  void _toggleCurrentDay() {
    setState(() {
      if (_selectedDays.contains(_currentDayIndex)) {
        _selectedDays.remove(_currentDayIndex);
      } else {
        _selectedDays.add(_currentDayIndex);
        _selectedDays.sort();
      }
    });
  }

  Future<void> _openAddExercise() async {
    // If current day is not in selectedDays, automatically activate it as a training day
    if (!_selectedDays.contains(_currentDayIndex)) {
      setState(() {
        _selectedDays.add(_currentDayIndex);
        _selectedDays.sort();
      });
    }

    final selectedExercise = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (_) => const ExerciseLibraryScreen(isPickerMode: true),
      ),
    );

    if (selectedExercise != null) {
      final currentList = _dayExercises[_currentDayIndex] ?? [];
      final defaultReps = (selectedExercise.exerciseType == ExerciseType.duration ||
              selectedExercise.exerciseType == ExerciseType.cardio ||
              selectedExercise.exerciseType == ExerciseType.distance)
          ? 0
          : 10;
      final defaultDuration = selectedExercise.exerciseType == ExerciseType.duration
          ? 60
          : (selectedExercise.exerciseType == ExerciseType.cardio
              ? 1200
              : (selectedExercise.exerciseType == ExerciseType.distance ? 300 : 0));
      final defaultDistance = selectedExercise.exerciseType == ExerciseType.distance ? 1.0 : 0.0;

      final planEx = PlanExercise(
        id: const Uuid().v4(),
        planId: widget.existingPlan?.id ?? 'temp',
        exerciseId: selectedExercise.id,
        exerciseName: selectedExercise.name,
        exerciseMuscle: selectedExercise.muscleGroup,
        exerciseType: selectedExercise.exerciseType,
        sortOrder: currentList.length,
        dayOfWeek: _currentDayIndex,
        targetSets: 3,
        targetReps: defaultReps,
        targetWeight: 0,
        targetDurationSeconds: defaultDuration,
        targetDistanceKm: defaultDistance,
        restSeconds: 60,
      );

      setState(() {
        currentList.add(planEx);
        _dayExercises[_currentDayIndex] = currentList;
      });
    }
  }

  void _showCopyFromDialog() {
    final availableDays = _selectedDays
        .where((d) => d != _currentDayIndex && (_dayExercises[d]?.isNotEmpty ?? false))
        .toList();
    if (availableDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other days with exercises to copy from.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Copy exercises to ${_dayFullNames[_currentDayIndex]} from:',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 12),
                ...availableDays.map((d) {
                  final exCount = _dayExercises[d]?.length ?? 0;
                  return ListTile(
                    leading: const Icon(Icons.copy_rounded, color: AppColors.primaryLight),
                    title: Text('${_dayFullNames[d]} ($exCount exercises)', style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      final sourceList = _dayExercises[d] ?? [];
                      final copied = sourceList.map((e) => e.copyWith(
                        id: const Uuid().v4(),
                        dayOfWeek: _currentDayIndex,
                      )).toList();
                      setState(() {
                        if (!_selectedDays.contains(_currentDayIndex)) {
                          _selectedDays.add(_currentDayIndex);
                          _selectedDays.sort();
                        }
                        _dayExercises[_currentDayIndex] = [
                          ...(_dayExercises[_currentDayIndex] ?? []),
                          ...copied,
                        ];
                      });
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _savePlan() async {
    FocusScope.of(context).unfocus();
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a plan name')),
      );
      return;
    }

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one workout day')),
      );
      return;
    }

    final planId = widget.existingPlan?.id ?? const Uuid().v4();
    final now = DateTime.now();

    final allExercises = <PlanExercise>[];
    for (final day in _selectedDays) {
      final dayList = _dayExercises[day] ?? [];
      for (var i = 0; i < dayList.length; i++) {
        allExercises.add(dayList[i].copyWith(
          planId: planId,
          dayOfWeek: day,
          sortOrder: i,
        ));
      }
    }

    final plan = WorkoutPlan(
      id: planId,
      name: name,
      description: _descriptionController.text.trim(),
      colorIndex: widget.existingPlan?.colorIndex ?? 0,
      createdAt: widget.existingPlan?.createdAt ?? now,
      updatedAt: now,
      daysOfWeek: _selectedDays,
      exercises: allExercises,
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
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.translucent,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Workout Days',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${_selectedDays.length} selected',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) {
                      final isCurrent = _currentDayIndex == i;
                      final isTrainingDay = _selectedDays.contains(i);
                      final count = _dayExercises[i]?.length ?? 0;

                      return GestureDetector(
                        onTap: () => _onDayTapped(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: isCurrent
                                ? AppColors.primary.withValues(alpha: 0.25)
                                : (isTrainingDay ? AppColors.surfaceGlass : Colors.transparent),
                            border: Border.all(
                              color: isCurrent
                                  ? AppColors.primaryLight
                                  : (isTrainingDay ? AppColors.borderGlass : Colors.white.withValues(alpha: 0.08)),
                              width: isCurrent ? 2.0 : 1.0,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _dayNames[i],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isCurrent ? FontWeight.w700 : (isTrainingDay ? FontWeight.w600 : FontWeight.w500),
                                  color: isCurrent
                                      ? Colors.white
                                      : (isTrainingDay ? AppColors.textPrimary : AppColors.textMuted),
                                ),
                              ),
                              const SizedBox(height: 3),
                              if (isTrainingDay)
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: count > 0 ? AppColors.primaryLight : AppColors.accentGreen,
                                  ),
                                )
                              else
                                Text(
                                  '—',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textMuted.withValues(alpha: 0.5),
                                    height: 0.8,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 14),

                  // Day status banner
                  Builder(
                    builder: (context) {
                      final isTrainingDay = _selectedDays.contains(_currentDayIndex);
                      final currentExercises = _dayExercises[_currentDayIndex] ?? [];
                      final hasOtherDaysWithExercises = _selectedDays.any(
                        (d) => d != _currentDayIndex && (_dayExercises[d]?.isNotEmpty ?? false),
                      );

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderGlass),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _dayFullNames[_currentDayIndex],
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isTrainingDay
                                        ? '${currentExercises.length} ${currentExercises.length == 1 ? 'exercise' : 'exercises'} configured'
                                        : 'Rest Day (no workouts scheduled)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isTrainingDay ? AppColors.accentGreen : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (hasOtherDaysWithExercises && isTrainingDay) ...[
                              IconButton(
                                tooltip: 'Copy from another day',
                                onPressed: _showCopyFromDialog,
                                icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primaryLight),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                              const SizedBox(width: 8),
                            ],
                            InkWell(
                              onTap: _toggleCurrentDay,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isTrainingDay
                                      ? AppColors.primary.withValues(alpha: 0.15)
                                      : AppColors.surfaceGlass,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isTrainingDay
                                        ? AppColors.primaryLight.withValues(alpha: 0.4)
                                        : AppColors.borderGlass,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isTrainingDay ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                                      size: 14,
                                      color: isTrainingDay ? AppColors.primaryLight : AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isTrainingDay ? 'Training Day' : 'Rest Day',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isTrainingDay ? AppColors.primaryLight : AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Exercises Section Header
                  Builder(
                    builder: (context) {
                      final isTrainingDay = _selectedDays.contains(_currentDayIndex);
                      final currentExercises = _dayExercises[_currentDayIndex] ?? [];

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${_dayFullNames[_currentDayIndex]} Exercises (${currentExercises.length})',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isTrainingDay)
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _openAddExercise,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_rounded, size: 16, color: AppColors.primaryLight),
                                      SizedBox(width: 4),
                                      Text(
                                        'Add Exercise',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Exercises Content
                  Builder(
                    builder: (context) {
                      final isTrainingDay = _selectedDays.contains(_currentDayIndex);
                      final currentExercises = _dayExercises[_currentDayIndex] ?? [];

                      if (!isTrainingDay) {
                        return GlassCard(
                          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.surfaceGlass,
                                  border: Border.all(color: AppColors.borderGlass),
                                ),
                                child: const Icon(Icons.bed_rounded, size: 36, color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                '${_dayFullNames[_currentDayIndex]} is a Rest Day',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Take time to recover, or make it a training day to add exercises.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 18),
                              GlassButton(
                                label: 'Make Training Day',
                                icon: Icons.fitness_center_rounded,
                                variant: GlassButtonVariant.primary,
                                height: 42,
                                onPressed: _toggleCurrentDay,
                              ),
                            ],
                          ),
                        );
                      }

                      if (currentExercises.isEmpty) {
                        return GlassCard(
                          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                          child: Column(
                            children: [
                              const Icon(Icons.fitness_center_rounded, size: 36, color: AppColors.textMuted),
                              const SizedBox(height: 10),
                              Text(
                                'No exercises configured for ${_dayFullNames[_currentDayIndex]}',
                                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white70),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GlassButton(
                                    label: 'Add Exercise',
                                    icon: Icons.add_rounded,
                                    variant: GlassButtonVariant.secondary,
                                    height: 40,
                                    onPressed: _openAddExercise,
                                  ),
                                  if (_selectedDays.any((d) => d != _currentDayIndex && (_dayExercises[d]?.isNotEmpty ?? false))) ...[
                                    const SizedBox(width: 12),
                                    GlassButton(
                                      label: 'Copy from Day',
                                      icon: Icons.copy_rounded,
                                      variant: GlassButtonVariant.ghost,
                                      height: 40,
                                      onPressed: _showCopyFromDialog,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );
                      }

                      return ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: currentExercises.length,
                        // ignore: deprecated_member_use
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex--;
                            final item = currentExercises.removeAt(oldIndex);
                            currentExercises.insert(newIndex, item);
                            _dayExercises[_currentDayIndex] = currentExercises;
                          });
                        },
                        itemBuilder: (context, index) {
                          final ex = currentExercises[index];
                          return _buildExerciseTile(ex, index);
                        },
                      );
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
                      final currentList = _dayExercises[_currentDayIndex] ?? [];
                      if (index >= 0 && index < currentList.length) {
                        currentList.removeAt(index);
                        _dayExercises[_currentDayIndex] = currentList;
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildExerciseFields(ex, index),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseFields(PlanExercise ex, int index) {
    final currentList = _dayExercises[_currentDayIndex] ?? [];

    switch (ex.exerciseType) {
      case ExerciseType.duration:
        // Sets and Duration/Time only. NO REPS!
        final durationSec = ex.targetDurationSeconds > 0 ? ex.targetDurationSeconds : 60;
        return Row(
          children: [
            Expanded(
              child: _selectorRow(
                label: 'Sets',
                value: '${ex.targetSets}',
                onDecrement: () {
                  if (ex.targetSets > 1) {
                    setState(() {
                      currentList[index] = ex.copyWith(targetSets: ex.targetSets - 1);
                      _dayExercises[_currentDayIndex] = currentList;
                    });
                  }
                },
                onIncrement: () {
                  setState(() {
                    currentList[index] = ex.copyWith(targetSets: ex.targetSets + 1);
                    _dayExercises[_currentDayIndex] = currentList;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DurationSelector(
                key: ValueKey('dur_${ex.id}'),
                durationSeconds: durationSec,
                onChanged: (newSec) {
                  setState(() {
                    currentList[index] = ex.copyWith(targetDurationSeconds: newSec);
                    _dayExercises[_currentDayIndex] = currentList;
                  });
                },
              ),
            ),
          ],
        );

      case ExerciseType.cardio:
        final durationSec = ex.targetDurationSeconds > 0 ? ex.targetDurationSeconds : 1200;
        return Row(
          children: [
            Expanded(
              child: _selectorRow(
                label: 'Sets',
                value: '${ex.targetSets}',
                onDecrement: () {
                  if (ex.targetSets > 1) {
                    setState(() {
                      currentList[index] = ex.copyWith(targetSets: ex.targetSets - 1);
                      _dayExercises[_currentDayIndex] = currentList;
                    });
                  }
                },
                onIncrement: () {
                  setState(() {
                    currentList[index] = ex.copyWith(targetSets: ex.targetSets + 1);
                    _dayExercises[_currentDayIndex] = currentList;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _selectorRow(
                label: 'Time',
                value: _formatDuration(durationSec),
                onDecrement: () {
                  if (durationSec > 60) {
                    setState(() {
                      currentList[index] = ex.copyWith(targetDurationSeconds: durationSec - 60);
                      _dayExercises[_currentDayIndex] = currentList;
                    });
                  }
                },
                onIncrement: () {
                  setState(() {
                    currentList[index] = ex.copyWith(targetDurationSeconds: durationSec + 60);
                    _dayExercises[_currentDayIndex] = currentList;
                  });
                },
              ),
            ),
          ],
        );

      case ExerciseType.distance:
        // Sets, Distance, and Duration/Time
        final dist = ex.targetDistanceKm > 0 ? ex.targetDistanceKm : 1.0;
        final durationSec = ex.targetDurationSeconds > 0 ? ex.targetDurationSeconds : 300;
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _selectorRow(
                    label: 'Sets',
                    value: '${ex.targetSets}',
                    onDecrement: () {
                      if (ex.targetSets > 1) {
                        setState(() {
                          currentList[index] = ex.copyWith(targetSets: ex.targetSets - 1);
                          _dayExercises[_currentDayIndex] = currentList;
                        });
                      }
                    },
                    onIncrement: () {
                      setState(() {
                        currentList[index] = ex.copyWith(targetSets: ex.targetSets + 1);
                        _dayExercises[_currentDayIndex] = currentList;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _selectorRow(
                    label: 'Distance',
                    value: '${dist.toStringAsFixed(1)} km',
                    onDecrement: () {
                      if (dist > 0.5) {
                        setState(() {
                          currentList[index] = ex.copyWith(targetDistanceKm: dist - 0.5);
                          _dayExercises[_currentDayIndex] = currentList;
                        });
                      }
                    },
                    onIncrement: () {
                      setState(() {
                        currentList[index] = ex.copyWith(targetDistanceKm: dist + 0.5);
                        _dayExercises[_currentDayIndex] = currentList;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _selectorRow(
              label: 'Target Time',
              value: _formatDuration(durationSec),
              onDecrement: () {
                if (durationSec > 30) {
                  setState(() {
                    currentList[index] = ex.copyWith(targetDurationSeconds: durationSec - 30);
                    _dayExercises[_currentDayIndex] = currentList;
                  });
                }
              },
              onIncrement: () {
                setState(() {
                  currentList[index] = ex.copyWith(targetDurationSeconds: durationSec + 30);
                  _dayExercises[_currentDayIndex] = currentList;
                });
              },
            ),
          ],
        );

      case ExerciseType.strength:
      case ExerciseType.weightAndReps:
      case ExerciseType.repsOnly:
      case ExerciseType.bodyweight:
        // Sets and Reps
        return Row(
          children: [
            Expanded(
              child: _selectorRow(
                label: 'Sets',
                value: '${ex.targetSets}',
                onDecrement: () {
                  if (ex.targetSets > 1) {
                    setState(() {
                      currentList[index] = ex.copyWith(targetSets: ex.targetSets - 1);
                      _dayExercises[_currentDayIndex] = currentList;
                    });
                  }
                },
                onIncrement: () {
                  setState(() {
                    currentList[index] = ex.copyWith(targetSets: ex.targetSets + 1);
                    _dayExercises[_currentDayIndex] = currentList;
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
                      currentList[index] = ex.copyWith(targetReps: ex.targetReps - 1);
                      _dayExercises[_currentDayIndex] = currentList;
                    });
                  }
                },
                onIncrement: () {
                  setState(() {
                    currentList[index] = ex.copyWith(targetReps: ex.targetReps + 1);
                    _dayExercises[_currentDayIndex] = currentList;
                  });
                },
              ),
            ),
          ],
        );
    }
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '0s';
    if (seconds < 60) return '${seconds}s';
    final mins = seconds ~/ 60;
    final rem = seconds % 60;
    if (rem == 0) return '${mins}m';
    return '${mins}m ${rem}s';
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

class _DurationSelector extends StatefulWidget {
  const _DurationSelector({
    required this.durationSeconds,
    required this.onChanged,
    super.key,
  });

  final int durationSeconds;
  final ValueChanged<int> onChanged;

  @override
  State<_DurationSelector> createState() => _DurationSelectorState();
}

class _DurationSelectorState extends State<_DurationSelector> {
  static const int _step = 15;
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isEditing = false;
  late int _lastValidSeconds;

  @override
  void initState() {
    super.initState();
    _lastValidSeconds = widget.durationSeconds > 0 ? widget.durationSeconds : 60;
    _controller = TextEditingController(text: '$_lastValidSeconds');
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _DurationSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && widget.durationSeconds != oldWidget.durationSeconds) {
      if (widget.durationSeconds > 0) {
        _lastValidSeconds = widget.durationSeconds;
      }
      _controller.text = '${widget.durationSeconds > 0 ? widget.durationSeconds : _lastValidSeconds}';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      setState(() {
        _isEditing = true;
        _controller.text = '${widget.durationSeconds > 0 ? widget.durationSeconds : _lastValidSeconds}';
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      });
    } else {
      _finishEditing();
    }
  }

  void _finishEditing() {
    final text = _controller.text.trim();
    final val = int.tryParse(text);
    if (val != null && val > 0) {
      _lastValidSeconds = val;
      widget.onChanged(val);
    } else {
      final fallback = _lastValidSeconds > 0 ? _lastValidSeconds : 60;
      _controller.text = '$fallback';
      widget.onChanged(fallback);
    }
    if (mounted) {
      setState(() {
        _isEditing = false;
      });
    }
  }

  void _increment() {
    int current = int.tryParse(_controller.text.trim()) ?? widget.durationSeconds;
    if (current <= 0) current = _lastValidSeconds;
    final next = current + _step;
    _lastValidSeconds = next;
    _controller.text = '$next';
    if (_isEditing) {
      _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
    }
    widget.onChanged(next);
  }

  void _decrement() {
    int current = int.tryParse(_controller.text.trim()) ?? widget.durationSeconds;
    if (current <= 0) current = _lastValidSeconds;
    final prev = current > _step
        ? current - _step
        : (current > 5 ? current - 5 : 1);
    if (prev != current) {
      _lastValidSeconds = prev;
      _controller.text = '$prev';
      if (_isEditing) {
        _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
      }
      widget.onChanged(prev);
    }
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '0s';
    if (seconds < 60) return '${seconds}s';
    final mins = seconds ~/ 60;
    final rem = seconds % 60;
    if (rem == 0) return '${mins}m';
    return '${mins}m ${rem}s';
  }

  @override
  Widget build(BuildContext context) {
    final currentSeconds = widget.durationSeconds > 0 ? widget.durationSeconds : _lastValidSeconds;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isEditing
              ? AppColors.primary.withValues(alpha: 0.6)
              : AppColors.borderGlass,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Time', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                if (_isEditing)
                  Text(
                    _formatDuration(currentSeconds),
                    style: const TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _decrement,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                  child: Icon(
                    Icons.remove_circle_outline_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              if (_isEditing)
                SizedBox(
                  width: 52,
                  height: 28,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(5),
                    ],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
                      hintText: 'sec',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      suffixText: 's',
                      suffixStyle: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    onChanged: (text) {
                      final val = int.tryParse(text.trim());
                      if (val != null && val > 0) {
                        _lastValidSeconds = val;
                        widget.onChanged(val);
                      }
                    },
                    onSubmitted: (_) => _finishEditing(),
                  ),
                )
              else
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isEditing = true;
                      _controller.text = '${widget.durationSeconds > 0 ? widget.durationSeconds : _lastValidSeconds}';
                      _controller.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _controller.text.length,
                      );
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _focusNode.requestFocus();
                      }
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primaryLight.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatDuration(currentSeconds),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.edit_rounded,
                          size: 11,
                          color: AppColors.primaryLight.withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: _increment,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                  child: Icon(
                    Icons.add_circle_outline_rounded,
                    size: 18,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
