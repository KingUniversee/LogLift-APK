import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/models/workout_plan.dart';
import '../../providers/active_workout_provider.dart';
import 'active_workout_screen.dart';

class StartWorkoutScreen extends ConsumerStatefulWidget {
  const StartWorkoutScreen({
    required this.plan,
    this.initialDayIndex,
    super.key,
  });

  final WorkoutPlan plan;
  final int? initialDayIndex;

  @override
  ConsumerState<StartWorkoutScreen> createState() => _StartWorkoutScreenState();
}

class _StartWorkoutScreenState extends ConsumerState<StartWorkoutScreen> {
  late int _selectedDayIndex;

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _dayFullNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    final todayIndex = (DateTime.now().weekday - 1) % 7;
    if (widget.initialDayIndex != null) {
      _selectedDayIndex = widget.initialDayIndex!;
    } else if (widget.plan.daysOfWeek.contains(todayIndex)) {
      _selectedDayIndex = todayIndex;
    } else if (widget.plan.daysOfWeek.isNotEmpty) {
      _selectedDayIndex = widget.plan.daysOfWeek.first;
    } else {
      _selectedDayIndex = todayIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercises = widget.plan.getExercisesForDay(_selectedDayIndex);
    final estDuration = widget.plan.estimatedDurationMinutesForDay(_selectedDayIndex);
    final hasMultipleDays = widget.plan.daysOfWeek.length > 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plan.name),
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
                    widget.plan.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_dayFullNames[_selectedDayIndex]} · Estimated time: ~$estDuration min · ${exercises.length} exercises',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  // Day selector chips if plan has multiple scheduled days
                  if (hasMultipleDays) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: widget.plan.daysOfWeek.map((day) {
                          final isSelected = day == _selectedDayIndex;
                          final exCount = widget.plan.getExercisesForDay(day).length;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              selected: isSelected,
                              onSelected: (val) {
                                if (val) setState(() => _selectedDayIndex = day);
                              },
                              label: Text('${_dayNames[day]} ($exCount)'),
                              selectedColor: AppColors.primary,
                              backgroundColor: AppColors.surfaceGlass,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected ? AppColors.primaryLight : AppColors.borderGlass,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Start Workout Primary Button
                  GlassButton(
                    label: 'Start Workout',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () async {
                      await ref.read(activeWorkoutProvider.notifier).startWorkout(
                            plan: widget.plan,
                            dayIndex: _selectedDayIndex,
                          );
                      if (context.mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_dayNames[_selectedDayIndex]} Exercises (${exercises.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: exercises.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bed_rounded, size: 40, color: AppColors.textMuted),
                                const SizedBox(height: 10),
                                Text(
                                  'No exercises scheduled for ${_dayFullNames[_selectedDayIndex]}',
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: exercises.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final ex = exercises[index];
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
                                            ex.targetSummary,
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
