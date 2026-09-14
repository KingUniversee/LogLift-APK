import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_bottom_sheet.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/models/exercise.dart';
import '../../data/models/workout_session.dart';
import '../../providers/active_workout_provider.dart';
import '../../providers/app_providers.dart';
import '../exercises/exercise_library_screen.dart';
import 'exercise_comparison_screen.dart';
import 'log_set_modal.dart';
import 'workout_summary_screen.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  Future<void> _handleFinishWorkout() async {
    final active = ref.read(activeWorkoutProvider);
    if (active.session == null) return;

    final completedSets = active.session!.completedSets;
    if (completedSets == 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Finish without completed sets?'),
          content: const Text('You have not marked any sets as completed yet.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Finish Anyway')),
          ],
        ),
      );
      if (confirm != true) return;
    }

    final finishedSession = await ref.read(activeWorkoutProvider.notifier).finishWorkout();

    if (finishedSession != null && mounted) {
      final detectedPrs = ref.read(activeWorkoutProvider).lastDetectedPRs;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WorkoutSummaryScreen(
            session: finishedSession,
            newPrs: detectedPrs,
          ),
        ),
      );
    }
  }

  Future<void> _confirmCancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Workout?'),
        content: const Text('Are you sure you want to discard this workout? Progress will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep Training')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.accentRose),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(activeWorkoutProvider.notifier).cancelWorkout();
      if (mounted) Navigator.of(context).pop();
    }
  }

  String _formatSeconds(int sec) {
    final m = (sec / 60).floor().toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final activeState = ref.watch(activeWorkoutProvider);
    final session = activeState.session;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: const Center(
          child: Text('No active workout session', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final currentLog = activeState.currentExerciseLog;
    final exerciseIndex = activeState.currentExerciseIndex;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          tooltip: 'Minimize workout',
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentLog?.exerciseName ?? session.planName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            if (currentLog != null)
              Text(
                'Exercise ${exerciseIndex + 1} of ${session.logs.length}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.accentRose),
            tooltip: 'Cancel workout',
            onPressed: _confirmCancel,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _handleFinishWorkout,
              child: const Text(
                'Finish',
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
            child: Column(
              children: [
                // Top Status bar: Elapsed time & total completed sets
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 16, color: AppColors.primaryLight),
                          const SizedBox(width: 6),
                          Text(
                            _formatSeconds(activeState.elapsedSeconds),
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white70),
                          ),
                        ],
                      ),
                      Text(
                        '${session.completedSets} sets completed',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.accentGreen),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Circular Rest Timer Card
                _buildRestTimerCard(activeState),
                const SizedBox(height: 12),

                // Set logging list
                Expanded(
                  child: currentLog == null
                      ? const Center(child: Text('No exercises added yet'))
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          children: [
                            // Previous performance comparison banner
                            _buildPreviousPerformanceBanner(currentLog),
                            const SizedBox(height: 14),

                            // Sets Header Row
                            const Row(
                              children: [
                                SizedBox(width: 32, child: Text('SET', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold))),
                                Expanded(child: Center(child: Text('KG', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)))),
                                Expanded(child: Center(child: Text('REPS', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)))),
                                SizedBox(width: 48, child: Center(child: Text('DONE', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)))),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Sets list
                            ...currentLog.sets.map((set) => _buildSetRow(currentLog, set)),
                            const SizedBox(height: 12),

                            // "+ Add Set" button
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.borderGlassHighlight),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {
                                ref.read(activeWorkoutProvider.notifier).addSet(currentLog.id);
                              },
                              icon: const Icon(Icons.add_rounded, color: AppColors.primaryLight, size: 20),
                              label: const Text('Add Set', style: TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                ),

                // Bottom Exercise Switcher Bar
                _buildExerciseSwitcher(session, exerciseIndex),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestTimerCard(ActiveWorkoutState state) {
    final isRunning = state.isRestTimerRunning;
    final remaining = state.restSecondsRemaining;
    final initial = state.initialRestSeconds > 0 ? state.initialRestSeconds : 60;
    final progress = isRunning ? (remaining / initial).clamp(0.0, 1.0) : 1.0;

    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      borderRadius: 20,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Circular Timer Dial
          GestureDetector(
            onTap: () {
              if (isRunning) {
                ref.read(activeWorkoutProvider.notifier).stopRestTimer();
              } else {
                ref.read(activeWorkoutProvider.notifier).startRestTimer(60);
              }
            },
            child: SizedBox(
              width: 68,
              height: 68,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isRunning ? AppColors.accentCyan : AppColors.primary,
                    ),
                  ),
                  Icon(
                    isRunning ? Icons.pause_rounded : Icons.timer_outlined,
                    color: isRunning ? AppColors.accentCyan : AppColors.primaryLight,
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRunning ? _formatSeconds(remaining) : 'Rest Timer',
                  style: TextStyle(
                    fontSize: isRunning ? 26 : 18,
                    fontWeight: FontWeight.w800,
                    color: isRunning ? AppColors.accentCyan : Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  isRunning ? 'Rest Time Remaining' : 'Tap dial to start 60s rest',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),

          if (isRunning)
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined, color: AppColors.accentRose),
              onPressed: () => ref.read(activeWorkoutProvider.notifier).stopRestTimer(),
              tooltip: 'Cancel timer',
            ),
        ],
      ),
    );
  }

  Widget _buildPreviousPerformanceBanner(ExerciseLog currentLog) {
    return FutureBuilder<ExerciseLog?>(
      future: ref.read(sessionRepoProvider).getPreviousExercisePerformance(
            currentLog.exerciseId,
            excludeSessionId: currentLog.sessionId,
          ),
      builder: (context, snapshot) {
        final prevLog = snapshot.data;
        return GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ExerciseComparisonScreen(
                  currentLog: currentLog,
                  previousLog: prevLog,
                ),
              ),
            );
          },
          child: Row(
            children: [
              const Icon(Icons.history_rounded, size: 18, color: AppColors.primaryLight),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  prevLog == null
                      ? 'No previous workout data (Tap to compare)'
                      : 'Previous: ${prevLog.maxWeight.toStringAsFixed(0)} kg × ${prevLog.totalReps} reps',
                  style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSetRow(ExerciseLog log, SetLog set) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        borderRadius: 14,
        borderColor: set.completed ? AppColors.accentGreen.withValues(alpha: 0.3) : AppColors.borderGlass,
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '${set.setNumber}',
                style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white70),
              ),
            ),

            // Weight input button
            Expanded(
              child: InkWell(
                onTap: () => _openSetEditModal(log, set),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      set.weightKg > 0
                          ? set.weightKg.toStringAsFixed(set.weightKg.truncateToDouble() == set.weightKg ? 0 : 1)
                          : '-',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Reps input button
            Expanded(
              child: InkWell(
                onTap: () => _openSetEditModal(log, set),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      set.reps > 0 ? '${set.reps}' : '-',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Complete check button
            IconButton(
              icon: Icon(
                set.completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: set.completed ? AppColors.accentGreen : AppColors.textMuted,
                size: 26,
              ),
              onPressed: () {
                ref.read(activeWorkoutProvider.notifier).toggleSetComplete(log.id, set.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openSetEditModal(ExerciseLog log, SetLog set) {
    showGlassBottomSheet(
      context: context,
      builder: (context) => LogSetModal(
        exerciseName: log.exerciseName,
        setLog: set,
        onSave: (weight, reps, rest, notes) {
          ref.read(activeWorkoutProvider.notifier).updateSet(
                log.id,
                set.id,
                weightKg: weight,
                reps: reps,
                notes: notes,
              );
        },
      ),
    );
  }

  Widget _buildExerciseSwitcher(WorkoutSession session, int currentIndex) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.92),
        border: const Border(top: BorderSide(color: AppColors.borderGlass)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: session.logs.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final log = session.logs[index];
                  final isSelected = index == currentIndex;
                  final isFinished = log.completedSets > 0 && log.completedSets == log.sets.length;

                  return GestureDetector(
                    onTap: () => ref.read(activeWorkoutProvider.notifier).setCurrentExercise(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isFinished ? AppColors.accentGreen.withValues(alpha: 0.15) : AppColors.surfaceGlass),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryLight : AppColors.borderGlass,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (isFinished) ...[
                            const Icon(Icons.check, size: 14, color: AppColors.accentGreen),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            log.exerciseName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primaryLight),
            tooltip: 'Add exercise to session',
            onPressed: () async {
              final selected = await Navigator.of(context).push<Exercise>(
                MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen(isPickerMode: true)),
              );
              if (selected != null) {
                await ref.read(activeWorkoutProvider.notifier).addExercise(selected);
              }
            },
          ),
        ],
      ),
    );
  }
}
