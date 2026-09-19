import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlog/data/models/app_settings.dart';
import 'package:liftlog/data/models/exercise.dart';
import 'package:liftlog/data/models/personal_record.dart';
import 'package:liftlog/data/models/user_profile.dart';
import 'package:liftlog/data/models/workout_plan.dart';
import 'package:liftlog/data/models/workout_session.dart';
import 'package:liftlog/data/repositories/workout_session_repository.dart';
import 'package:liftlog/features/auth/login_screen.dart';
import 'package:liftlog/features/shell/main_shell.dart';
import 'package:liftlog/features/workout_plans/create_workout_plan_screen.dart';
import 'package:liftlog/main.dart';
import 'package:liftlog/providers/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders AuthGate and SplashScreen requiring Sign In or Account Creation', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: WorkoutLogApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('LiftLog'), findsOneWidget);
    expect(find.text('Build Better Habits\nTrack Your Progress'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    // Enforce that "Get Started" bypass is permanently removed
    expect(find.text('Get Started'), findsNothing);
  });

  testWidgets('renders MainShell and verifies dynamic empty states without fake data', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayPlanProvider.overrideWith((ref) => Future.value(null)),
          workoutPlansProvider.overrideWith(() => _MockWorkoutPlansNotifier()),
          completedSessionsProvider.overrideWith(() => _MockEmptySessionsNotifier()),
          allPrsProvider.overrideWith(() => _MockEmptyPrsNotifier()),
          exercisesProvider.overrideWith(() => _MockEmptyExercisesNotifier()),
          userProfileProvider.overrideWith(() => _MockUserProfileNotifier()),
          settingsProvider.overrideWith(() => _MockSettingsNotifier()),
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

  testWidgets('LoginScreen renders and scrolls without overflow in both keyboard-closed and keyboard-open states', (WidgetTester tester) async {
    // Typical mobile screen resolution
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith(() => _MockUserProfileNotifier()),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Keyboard-closed state
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Continue with Google'), findsNothing);
    expect(
      find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Sign Up')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    // 2. Simulate opening the soft keyboard (simulating bottom insets of 350 logical pixels = 700 physical pixels)
    tester.view.viewInsets = const FakeViewPadding(bottom: 700);
    await tester.pumpAndSettle();

    // Verify all key elements remain functional and no overflow error occurred
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Continue with Google'), findsNothing);
    expect(tester.takeException(), isNull);

    // Verify it scrolls smoothly when dragging
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Sign Up')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    // 3. Close the keyboard
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Duration exercise allows direct numeric typing and +/- controls without reps', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final planWithDuration = WorkoutPlan(
      id: 'plan-duration',
      name: 'Core Plan',
      description: 'Plank session',
      daysOfWeek: [0],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      exercises: [
        const PlanExercise(
          id: 'ex-plank',
          planId: 'plan-duration',
          exerciseId: 'plank',
          exerciseName: 'Plank',
          exerciseMuscle: MuscleGroup.core,
          exerciseType: ExerciseType.duration,
          sortOrder: 0,
          dayOfWeek: 0,
          targetSets: 3,
          targetReps: 0,
          targetDurationSeconds: 60,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutPlansProvider.overrideWith(() => _MockWorkoutPlansNotifier()),
        ],
        child: MaterialApp(
          home: CreateWorkoutPlanScreen(existingPlan: planWithDuration),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Sets is shown and Reps is NOT shown
    expect(find.text('Sets'), findsOneWidget);
    expect(find.text('Reps'), findsNothing);

    // 2. Verify initial duration displays "1m"
    expect(find.text('1m'), findsOneWidget);

    // 3. Tap on duration pill to open numeric input
    await tester.tap(find.text('1m'));
    await tester.pumpAndSettle();

    // 4. Verify TextField appears with text '60'
    final durationTextField = find.widgetWithText(TextField, '60');
    expect(durationTextField, findsOneWidget);
    await tester.enterText(durationTextField, '90');
    await tester.pumpAndSettle();

    // 5. Verify live sub-label shows "1m 30s" while editing
    expect(find.text('1m 30s'), findsOneWidget);

    // 6. Finish editing by submitting
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Verify duration pill displays "1m 30s"
    expect(find.text('1m 30s'), findsOneWidget);

    // 7. Tap increment button (+)
    final plusIcons = find.byIcon(Icons.add_circle_outline_rounded);
    expect(plusIcons, findsWidgets);
    // The second plus icon is for duration (first is for sets)
    await tester.tap(plusIcons.last);
    await tester.pumpAndSettle();

    // 90s + 15s = 105s -> "1m 45s"
    expect(find.text('1m 45s'), findsOneWidget);

    // 8. Tap decrement button (-)
    final minusIcons = find.byIcon(Icons.remove_circle_outline_rounded);
    expect(minusIcons, findsWidgets);
    await tester.tap(minusIcons.last);
    await tester.pumpAndSettle();

    // 105s - 15s = 90s -> "1m 30s"
    expect(find.text('1m 30s'), findsOneWidget);
  });

  testWidgets('CreateWorkoutPlanScreen displays dynamic Day 1, Day 2, Day 3, adds new day, and deletes day', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutPlansProvider.overrideWith(() => _MockWorkoutPlansNotifier()),
        ],
        child: const MaterialApp(
          home: CreateWorkoutPlanScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify default dynamic days: Day 1, Day 2, Day 3
    expect(find.text('Day 1'), findsWidgets);
    expect(find.text('Day 2'), findsWidgets);
    expect(find.text('Day 3'), findsWidgets);
    expect(find.text('Add Day'), findsOneWidget);
    expect(find.text('Continuous Rotating Split'), findsOneWidget);

    // 2. Tap Add Day to dynamically add Day 4
    await tester.tap(find.text('Add Day'));
    await tester.pumpAndSettle();

    expect(find.text('Day 4'), findsWidgets);
    expect(find.text('4 Days configured'), findsOneWidget);

    // 3. Delete Day 4 using the trash icon in Day banner
    final deleteDayButton = find.byTooltip('Delete Day 4');
    expect(deleteDayButton, findsOneWidget);
    await tester.tap(deleteDayButton);
    await tester.pumpAndSettle();

    // Verify it is back to 3 days configured
    expect(find.text('3 Days configured'), findsOneWidget);
    expect(find.text('Day 4'), findsNothing);
  });

  testWidgets('HomeScreen renders Leave Day hero state with Cancel Leave button when today is leave', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final today = DateTime.now();
    final todayKey = WorkoutPlan.formatDateKey(today);
    final leavePlan = WorkoutPlan(
      id: 'p-leave',
      name: 'Push Pull Legs',
      daysOfWeek: [0, 1, 2],
      currentSplitIndex: 0,
      leaveDates: [todayKey],
      createdAt: today,
      updatedAt: today,
      exercises: const [
        PlanExercise(
          id: 'e1',
          planId: 'p-leave',
          exerciseId: 'bench',
          exerciseName: 'Bench Press',
          exerciseMuscle: MuscleGroup.chest,
          exerciseType: ExerciseType.strength,
          sortOrder: 0,
          dayOfWeek: 0,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayPlanProvider.overrideWith((ref) => Future.value(leavePlan)),
          workoutPlansProvider.overrideWith(() => _MockWorkoutPlansNotifier()),
          completedSessionsProvider.overrideWith(() => _MockEmptySessionsNotifier()),
          allPrsProvider.overrideWith(() => _MockEmptyPrsNotifier()),
          exercisesProvider.overrideWith(() => _MockEmptyExercisesNotifier()),
          userProfileProvider.overrideWith(() => _MockUserProfileNotifier()),
          settingsProvider.overrideWith(() => _MockSettingsNotifier()),
          sessionRepoProvider.overrideWithValue(_MockSessionRepository()),
        ],
        child: const MaterialApp(
          home: MainShell(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('LEAVE DAY · ROUTINE PAUSED'), findsOneWidget);
    expect(find.text('Cancel Leave'), findsOneWidget);
    expect(find.text('Start Anyway'), findsOneWidget);
  });

  testWidgets('HomeScreen renders Rest Day (OFF in routine) hero state when effective day is OFF', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final today = DateTime.now();
    final offPlan = WorkoutPlan(
      id: 'p-off',
      name: 'Bro Split',
      daysOfWeek: [0, 1],
      currentSplitIndex: 1, // Day 2 has no exercises => OFF
      createdAt: today,
      updatedAt: today,
      exercises: const [
        PlanExercise(
          id: 'e1',
          planId: 'p-off',
          exerciseId: 'curl',
          exerciseName: 'Bicep Curl',
          exerciseMuscle: MuscleGroup.arms,
          exerciseType: ExerciseType.strength,
          sortOrder: 0,
          dayOfWeek: 0,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayPlanProvider.overrideWith((ref) => Future.value(offPlan)),
          workoutPlansProvider.overrideWith(() => _MockWorkoutPlansNotifier()),
          completedSessionsProvider.overrideWith(() => _MockEmptySessionsNotifier()),
          allPrsProvider.overrideWith(() => _MockEmptyPrsNotifier()),
          exercisesProvider.overrideWith(() => _MockEmptyExercisesNotifier()),
          userProfileProvider.overrideWith(() => _MockUserProfileNotifier()),
          settingsProvider.overrideWith(() => _MockSettingsNotifier()),
          sessionRepoProvider.overrideWithValue(_MockSessionRepository()),
        ],
        child: const MaterialApp(
          home: MainShell(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('REST DAY · DAY 2 (OFF IN ROUTINE)'), findsOneWidget);
    expect(find.text('Take Leave'), findsOneWidget);
    expect(find.text('Mark Rest Done'), findsOneWidget);
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

class _MockWorkoutPlansNotifier extends WorkoutPlansNotifier {
  @override
  Future<List<WorkoutPlan>> build() async => [];
}

class _MockUserProfileNotifier extends UserProfileNotifier {
  @override
  Future<UserProfile?> build() async => null;
}

class _MockSettingsNotifier extends SettingsNotifier {
  @override
  Future<AppSettings> build() async => const AppSettings();
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
