import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlog/data/models/exercise.dart';
import 'package:liftlog/data/models/personal_record.dart';
import 'package:liftlog/data/models/workout_session.dart';
import 'package:liftlog/data/repositories/workout_session_repository.dart';
import 'package:liftlog/features/shell/main_shell.dart';
import 'package:liftlog/main.dart';
import 'package:liftlog/providers/app_providers.dart';

void main() {
  testWidgets('renders SplashScreen with branding and get started button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: WorkoutLogApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Workout Log'), findsOneWidget);
    expect(find.text('Build Better Habits\nTrack Your Progress'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('renders MainShell and verifies dynamic empty states without fake data', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayPlanProvider.overrideWith((ref) => Future.value(null)),
          completedSessionsProvider.overrideWith(() => _MockEmptySessionsNotifier()),
          allPrsProvider.overrideWith(() => _MockEmptyPrsNotifier()),
          exercisesProvider.overrideWith(() => _MockEmptyExercisesNotifier()),
          sessionRepoProvider.overrideWithValue(_MockSessionRepository()),
        ],
        child: const MaterialApp(
          home: MainShell(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify empty state is displayed when database has no workouts
    expect(find.text('No workout scheduled for today'), findsOneWidget);
    expect(find.text('Create Workout Plan'), findsOneWidget);
    expect(find.text('Current Streak'), findsOneWidget);
    expect(find.text('Recent Progress'), findsOneWidget);

    // Verify bottom navigation items exist
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Workouts'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
  });
}

class _MockSessionRepository extends WorkoutSessionRepository {
  @override
  Future<WorkoutSession?> getActiveSession() async => null;

  @override
  Future<List<WorkoutSession>> getCompletedSessions({
    String? query,
    String? planId,
    String? exerciseId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async => [];
}

class _MockEmptySessionsNotifier extends CompletedSessionsNotifier {
  @override
  Future<List<WorkoutSession>> build() async => [];
}

class _MockEmptyPrsNotifier extends AllPrsNotifier {
  @override
  Future<List<PersonalRecord>> build() async => [];
}

class _MockEmptyExercisesNotifier extends ExercisesNotifier {
  @override
  Future<List<Exercise>> build() async => [];
}
