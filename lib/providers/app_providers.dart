import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/app_settings.dart';
import '../data/models/exercise.dart';
import '../data/models/personal_record.dart';
import '../data/models/user_profile.dart';
import '../data/models/workout_plan.dart';
import '../data/models/workout_session.dart';
import '../data/repositories/exercise_repository.dart';
import '../data/repositories/personal_record_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/user_profile_repository.dart';
import '../data/repositories/workout_plan_repository.dart';
import '../data/repositories/workout_session_repository.dart';
import '../services/comparison_engine.dart';
import '../services/pdf_export_service.dart';
import '../services/personal_record_engine.dart';
import '../services/report_service.dart';
import '../services/statistics_service.dart';
import '../services/streak_engine.dart';

import '../data/services/auth_service.dart';

// Repositories & Services
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final exerciseRepoProvider = Provider<ExerciseRepository>((ref) => ExerciseRepository());
final planRepoProvider = Provider<WorkoutPlanRepository>((ref) => WorkoutPlanRepository());
final sessionRepoProvider = Provider<WorkoutSessionRepository>((ref) => WorkoutSessionRepository());
final prRepoProvider = Provider<PersonalRecordRepository>((ref) => PersonalRecordRepository());
final settingsRepoProvider = Provider<SettingsRepository>((ref) => SettingsRepository());
final userProfileRepoProvider = Provider<UserProfileRepository>((ref) => UserProfileRepository());

// Services
final comparisonEngineProvider = Provider<ComparisonEngine>((ref) => const ComparisonEngine());
final streakEngineProvider = Provider<StreakEngine>((ref) => const StreakEngine());
final prEngineProvider = Provider<PersonalRecordEngine>((ref) {
  return PersonalRecordEngine(ref.watch(prRepoProvider));
});
final statisticsServiceProvider = Provider<StatisticsService>((ref) {
  return StatisticsService(streakEngine: ref.watch(streakEngineProvider));
});
final reportServiceProvider = Provider<ReportService>((ref) => const ReportService());
final pdfExportServiceProvider = Provider<PdfExportService>((ref) => const PdfExportService());

// User Profile & Authentication Notifier
class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    return ref.watch(authServiceProvider).getCurrentUser();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final user = await ref.read(authServiceProvider).register(
            name: name,
            email: email,
            password: password,
          );
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final user = await ref.read(authServiceProvider).login(
            email: email,
            password: password,
          );
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> loginWithGoogle(String idToken) async {
    state = const AsyncLoading();
    try {
      final user = await ref.read(authServiceProvider).loginWithGoogle(idToken);
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await ref.read(authServiceProvider).logout();
    state = const AsyncData(null);
  }

  Future<void> updateProfile(UserProfile profile) async {
    await ref.read(userProfileRepoProvider).saveProfile(profile);
    state = AsyncData(profile);
  }
}

final userProfileProvider = AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(
  UserProfileNotifier.new,
);

// Settings Notifier
class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    return ref.watch(settingsRepoProvider).getSettings();
  }

  Future<void> updateSettings(AppSettings settings) async {
    await ref.read(settingsRepoProvider).saveSettings(settings);
    state = AsyncData(settings);
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

// Exercises Notifier
class ExercisesNotifier extends AsyncNotifier<List<Exercise>> {
  String? _query;
  MuscleGroup? _muscleGroup;
  ExerciseType? _exerciseType;

  @override
  Future<List<Exercise>> build() async {
    return ref.watch(exerciseRepoProvider).getExercises(
          query: _query,
          muscleGroup: _muscleGroup,
          exerciseType: _exerciseType,
        );
  }

  Future<void> filter({String? query, MuscleGroup? muscleGroup, ExerciseType? exerciseType}) async {
    _query = query;
    _muscleGroup = muscleGroup;
    _exerciseType = exerciseType;
    ref.invalidateSelf();
  }

  Future<void> addExercise(Exercise exercise) async {
    await ref.read(exerciseRepoProvider).saveExercise(exercise);
    ref.invalidateSelf();
  }

  Future<void> deleteExercise(String id) async {
    await ref.read(exerciseRepoProvider).deleteExercise(id);
    ref.invalidateSelf();
  }
}

final exercisesProvider = AsyncNotifierProvider<ExercisesNotifier, List<Exercise>>(
  ExercisesNotifier.new,
);

// Workout Plans Notifier
class WorkoutPlansNotifier extends AsyncNotifier<List<WorkoutPlan>> {
  String? _query;

  @override
  Future<List<WorkoutPlan>> build() async {
    return ref.watch(planRepoProvider).getPlans(query: _query);
  }

  Future<void> search(String? query) async {
    _query = query;
    ref.invalidateSelf();
  }

  Future<void> savePlan(WorkoutPlan plan) async {
    await ref.read(planRepoProvider).savePlan(plan);
    ref.invalidateSelf();
    ref.invalidate(todayPlanProvider);
  }

  Future<void> deletePlan(String id) async {
    await ref.read(planRepoProvider).deletePlan(id);
    ref.invalidateSelf();
    ref.invalidate(todayPlanProvider);
  }

  Future<void> duplicatePlan(String id) async {
    await ref.read(planRepoProvider).duplicatePlan(id);
    ref.invalidateSelf();
  }
}

final workoutPlansProvider = AsyncNotifierProvider<WorkoutPlansNotifier, List<WorkoutPlan>>(
  WorkoutPlansNotifier.new,
);

// Today's Planned Workout Provider
final todayPlanProvider = FutureProvider<WorkoutPlan?>((ref) async {
  return ref.watch(planRepoProvider).getTodayPlan(DateTime.now());
});

// Completed Workout Sessions Notifier
class CompletedSessionsNotifier extends AsyncNotifier<List<WorkoutSession>> {
  String? _query;
  String? _planId;
  String? _exerciseId;

  @override
  Future<List<WorkoutSession>> build() async {
    return ref.watch(sessionRepoProvider).getCompletedSessions(
          query: _query,
          planId: _planId,
          exerciseId: _exerciseId,
        );
  }

  Future<void> filter({String? query, String? planId, String? exerciseId}) async {
    _query = query;
    _planId = planId;
    _exerciseId = exerciseId;
    ref.invalidateSelf();
  }

  Future<void> deleteSession(String id) async {
    await ref.read(sessionRepoProvider).deleteSession(id);
    ref.invalidateSelf();
    ref.invalidate(allPrsProvider);
    ref.invalidate(overallStatsProvider);
  }
}

final completedSessionsProvider = AsyncNotifierProvider<CompletedSessionsNotifier, List<WorkoutSession>>(
  CompletedSessionsNotifier.new,
);

// Personal Records Notifier
class AllPrsNotifier extends AsyncNotifier<List<PersonalRecord>> {
  @override
  Future<List<PersonalRecord>> build() async {
    return ref.watch(prRepoProvider).getAllPRs();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final allPrsProvider = AsyncNotifierProvider<AllPrsNotifier, List<PersonalRecord>>(
  AllPrsNotifier.new,
);

// Overall Statistics Provider (Derived from Sessions & PRs)
final overallStatsProvider = FutureProvider<OverallStats>((ref) async {
  final sessions = await ref.watch(completedSessionsProvider.future);
  final prs = await ref.watch(allPrsProvider.future);
  final exercises = await ref.watch(exercisesProvider.future);
  final statsService = ref.watch(statisticsServiceProvider);

  return statsService.computeStats(
    sessions: sessions,
    prs: prs,
    allExercises: exercises,
  );
});
