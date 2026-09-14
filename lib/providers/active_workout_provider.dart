import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/models/exercise.dart';
import '../data/models/personal_record.dart';
import '../data/models/workout_plan.dart';
import '../data/models/workout_session.dart';
import 'app_providers.dart';

class ActiveWorkoutState {
  const ActiveWorkoutState({
    this.session,
    this.currentExerciseIndex = 0,
    this.restSecondsRemaining = 0,
    this.initialRestSeconds = 60,
    this.isRestTimerRunning = false,
    this.elapsedSeconds = 0,
    this.lastDetectedPRs = const [],
  });

  final WorkoutSession? session;
  final int currentExerciseIndex;
  final int restSecondsRemaining;
  final int initialRestSeconds;
  final bool isRestTimerRunning;
  final int elapsedSeconds;
  final List<PersonalRecord> lastDetectedPRs;

  bool get hasActiveWorkout => session != null && session!.status == WorkoutStatus.inProgress;

  ExerciseLog? get currentExerciseLog {
    if (session == null || session!.logs.isEmpty) return null;
    if (currentExerciseIndex < 0 || currentExerciseIndex >= session!.logs.length) {
      return session!.logs.first;
    }
    return session!.logs[currentExerciseIndex];
  }

  ActiveWorkoutState copyWith({
    WorkoutSession? Function()? session,
    int? currentExerciseIndex,
    int? restSecondsRemaining,
    int? initialRestSeconds,
    bool? isRestTimerRunning,
    int? elapsedSeconds,
    List<PersonalRecord>? lastDetectedPRs,
  }) {
    return ActiveWorkoutState(
      session: session != null ? session() : this.session,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      restSecondsRemaining: restSecondsRemaining ?? this.restSecondsRemaining,
      initialRestSeconds: initialRestSeconds ?? this.initialRestSeconds,
      isRestTimerRunning: isRestTimerRunning ?? this.isRestTimerRunning,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      lastDetectedPRs: lastDetectedPRs ?? this.lastDetectedPRs,
    );
  }
}

class ActiveWorkoutNotifier extends Notifier<ActiveWorkoutState> {
  Timer? _ticker;

  @override
  ActiveWorkoutState build() {
    ref.onDispose(() {
      _ticker?.cancel();
    });
    return const ActiveWorkoutState();
  }

  Future<void> checkResumeInterruptedWorkout() async {
    final active = await ref.read(sessionRepoProvider).getActiveSession();
    if (active != null) {
      final elapsed = DateTime.now().difference(active.startedAt).inSeconds;
      state = state.copyWith(
        session: () => active,
        elapsedSeconds: elapsed > 0 ? elapsed : 0,
      );
      _startTicker();
    }
  }

  Future<void> startWorkout({
    WorkoutPlan? plan,
    String? customTitle,
    List<Exercise> exercises = const [],
  }) async {
    final sessionId = const Uuid().v4();
    final now = DateTime.now();

    final exerciseLogs = <ExerciseLog>[];

    if (plan != null) {
      for (var i = 0; i < plan.exercises.length; i++) {
        final planEx = plan.exercises[i];
        final logId = const Uuid().v4();
        final sets = List.generate(planEx.targetSets, (idx) {
          return SetLog(
            id: const Uuid().v4(),
            exerciseLogId: logId,
            setNumber: idx + 1,
            weightKg: planEx.targetWeight,
            reps: planEx.targetReps,
            completed: false,
          );
        });

        exerciseLogs.add(ExerciseLog(
          id: logId,
          sessionId: sessionId,
          exerciseId: planEx.exerciseId,
          exerciseName: planEx.exerciseName,
          exerciseType: planEx.exerciseType,
          sortOrder: i,
          sets: sets,
        ));
      }
    } else if (exercises.isNotEmpty) {
      for (var i = 0; i < exercises.length; i++) {
        final ex = exercises[i];
        final logId = const Uuid().v4();
        exerciseLogs.add(ExerciseLog(
          id: logId,
          sessionId: sessionId,
          exerciseId: ex.id,
          exerciseName: ex.name,
          exerciseType: ex.exerciseType,
          sortOrder: i,
          sets: [
            SetLog(
              id: const Uuid().v4(),
              exerciseLogId: logId,
              setNumber: 1,
              weightKg: 0,
              reps: 10,
              completed: false,
            ),
          ],
        ));
      }
    }

    final newSession = WorkoutSession(
      id: sessionId,
      planId: plan?.id,
      planName: plan?.name ?? customTitle ?? 'Custom Workout',
      startedAt: now,
      status: WorkoutStatus.inProgress,
      logs: exerciseLogs,
    );

    state = ActiveWorkoutState(
      session: newSession,
      currentExerciseIndex: 0,
      elapsedSeconds: 0,
    );

    _startTicker();
    await ref.read(sessionRepoProvider).saveSession(newSession);
  }

  void setCurrentExercise(int index) {
    if (state.session != null && index >= 0 && index < state.session!.logs.length) {
      state = state.copyWith(currentExerciseIndex: index);
    }
  }

  Future<void> addExercise(Exercise exercise) async {
    if (state.session == null) return;
    final logId = const Uuid().v4();
    final newLog = ExerciseLog(
      id: logId,
      sessionId: state.session!.id,
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      exerciseType: exercise.exerciseType,
      sortOrder: state.session!.logs.length,
      sets: [
        SetLog(
          id: const Uuid().v4(),
          exerciseLogId: logId,
          setNumber: 1,
          weightKg: 0,
          reps: 10,
          completed: false,
        ),
      ],
    );

    final updatedLogs = [...state.session!.logs, newLog];
    final updatedSession = state.session!.copyWith(logs: updatedLogs);
    state = state.copyWith(
      session: () => updatedSession,
      currentExerciseIndex: updatedLogs.length - 1,
    );
    await ref.read(sessionRepoProvider).saveSession(updatedSession);
  }

  Future<void> addSet(String exerciseLogId) async {
    if (state.session == null) return;
    final logs = state.session!.logs.map((log) {
      if (log.id == exerciseLogId) {
        final lastSet = log.sets.isNotEmpty ? log.sets.last : null;
        final newSet = SetLog(
          id: const Uuid().v4(),
          exerciseLogId: log.id,
          setNumber: log.sets.length + 1,
          weightKg: lastSet?.weightKg ?? 0.0,
          reps: lastSet?.reps ?? 10,
          completed: false,
        );
        return log.copyWith(sets: [...log.sets, newSet]);
      }
      return log;
    }).toList();

    final updated = state.session!.copyWith(logs: logs);
    state = state.copyWith(session: () => updated);
    await ref.read(sessionRepoProvider).saveSession(updated);
  }

  Future<void> updateSet(
    String exerciseLogId,
    String setId, {
    double? weightKg,
    int? reps,
    int? durationSeconds,
    double? distanceKm,
    String? notes,
  }) async {
    if (state.session == null) return;
    final logs = state.session!.logs.map((log) {
      if (log.id == exerciseLogId) {
        final sets = log.sets.map((s) {
          if (s.id == setId) {
            return s.copyWith(
              weightKg: weightKg ?? s.weightKg,
              reps: reps ?? s.reps,
              durationSeconds: durationSeconds ?? s.durationSeconds,
              distanceKm: distanceKm ?? s.distanceKm,
              notes: notes ?? s.notes,
            );
          }
          return s;
        }).toList();
        return log.copyWith(sets: sets);
      }
      return log;
    }).toList();

    final updated = state.session!.copyWith(logs: logs);
    state = state.copyWith(session: () => updated);
    await ref.read(sessionRepoProvider).saveSession(updated);
  }

  Future<void> toggleSetComplete(String exerciseLogId, String setId) async {
    if (state.session == null) return;
    var justCompleted = false;

    final logs = state.session!.logs.map((log) {
      if (log.id == exerciseLogId) {
        final sets = log.sets.map((s) {
          if (s.id == setId) {
            final nextState = !s.completed;
            if (nextState) justCompleted = true;
            return s.copyWith(completed: nextState);
          }
          return s;
        }).toList();
        return log.copyWith(sets: sets);
      }
      return log;
    }).toList();

    final updated = state.session!.copyWith(logs: logs);
    state = state.copyWith(session: () => updated);
    await ref.read(sessionRepoProvider).saveSession(updated);

    if (justCompleted) {
      HapticFeedback.mediumImpact();
      final settings = ref.read(settingsProvider).value;
      final restSec = settings?.defaultRestSeconds ?? 60;
      if (restSec > 0) {
        startRestTimer(restSec);
      }
    }
  }

  Future<void> deleteSet(String exerciseLogId, String setId) async {
    if (state.session == null) return;
    final logs = state.session!.logs.map((log) {
      if (log.id == exerciseLogId) {
        final filteredSets = log.sets.where((s) => s.id != setId).toList();
        final renumberedSets = List.generate(filteredSets.length, (i) {
          return filteredSets[i].copyWith(setNumber: i + 1);
        });
        return log.copyWith(sets: renumberedSets);
      }
      return log;
    }).toList();

    final updated = state.session!.copyWith(logs: logs);
    state = state.copyWith(session: () => updated);
    await ref.read(sessionRepoProvider).saveSession(updated);
  }

  void startRestTimer(int seconds) {
    state = state.copyWith(
      restSecondsRemaining: seconds,
      initialRestSeconds: seconds,
      isRestTimerRunning: true,
    );
  }

  void stopRestTimer() {
    state = state.copyWith(
      restSecondsRemaining: 0,
      isRestTimerRunning: false,
    );
  }

  Future<WorkoutSession?> finishWorkout() async {
    if (state.session == null) return null;
    _ticker?.cancel();

    final now = DateTime.now();
    final duration = now.difference(state.session!.startedAt).inSeconds;

    final completedSession = state.session!.copyWith(
      status: WorkoutStatus.completed,
      completedAt: now,
      durationSeconds: duration > 0 ? duration : 1,
    );

    // Save completed session to database
    await ref.read(sessionRepoProvider).saveSession(completedSession);

    // Run PR detection engine
    final prs = await ref.read(prEngineProvider).evaluateAndSaveSessionPRs(completedSession);

    state = state.copyWith(
      session: () => null,
      isRestTimerRunning: false,
      restSecondsRemaining: 0,
      lastDetectedPRs: prs,
    );

    // Invalidate dependent providers to reactively update Home, History, Progress, and Reports
    ref.invalidate(completedSessionsProvider);
    ref.invalidate(allPrsProvider);
    ref.invalidate(overallStatsProvider);
    ref.invalidate(todayPlanProvider);

    return completedSession;
  }

  Future<void> cancelWorkout() async {
    if (state.session == null) return;
    _ticker?.cancel();
    await ref.read(sessionRepoProvider).deleteSession(state.session!.id);
    state = const ActiveWorkoutState();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final newElapsed = state.elapsedSeconds + 1;
      var newRest = state.restSecondsRemaining;
      var timerRunning = state.isRestTimerRunning;

      if (timerRunning) {
        if (newRest > 1) {
          newRest--;
        } else {
          newRest = 0;
          timerRunning = false;
          HapticFeedback.heavyImpact();
        }
      }

      state = state.copyWith(
        elapsedSeconds: newElapsed,
        restSecondsRemaining: newRest,
        isRestTimerRunning: timerRunning,
      );
    });
  }
}

final activeWorkoutProvider = NotifierProvider<ActiveWorkoutNotifier, ActiveWorkoutState>(
  ActiveWorkoutNotifier.new,
);
