import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:liftlog/core/network/api_client.dart';
import 'package:liftlog/core/network/api_config.dart';
import 'package:liftlog/data/models/exercise.dart';
import 'package:liftlog/data/models/personal_record.dart';
import 'package:liftlog/data/models/workout_session.dart';
import 'package:liftlog/data/models/user_profile.dart';
import 'package:liftlog/data/models/workout_plan.dart';
import 'package:liftlog/data/repositories/user_profile_repository.dart';
import 'package:liftlog/data/repositories/workout_plan_repository.dart';
import 'package:liftlog/data/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ApiConfig Tests', () {
    test('Defaults to production base URL http://13.140.58.252:22658', () {
      expect(ApiConfig.baseUrl, equals('http://13.140.58.252:22658'));
      expect(ApiConfig.productionBaseUrl, equals('http://13.140.58.252:22658'));
    });
  });

  group('ApiClient and Token Lifecycle Tests', () {
    test('Stores and retrieves tokens securely in SharedPreferences', () async {
      final mockClient = MockClient((request) async => http.Response('{}', 200));
      final api = ApiClient(httpClient: mockClient);

      await api.setTokens(
        token: 'test_access_jwt_token',
        refreshToken: 'test_refresh_jwt_token',
        userId: 'user_123',
      );

      final token = await api.getAccessToken();
      final refreshToken = await api.getRefreshToken();
      final userId = await api.getActiveUserId();

      expect(token, equals('test_access_jwt_token'));
      expect(refreshToken, equals('test_refresh_jwt_token'));
      expect(userId, equals('user_123'));

      await api.clearTokens();
      expect(await api.getAccessToken(), isNull);
      expect(await api.getRefreshToken(), isNull);
      expect(await api.getActiveUserId(), isNull);
    });

    test('Attaches Authorization Bearer header to authenticated requests', () async {
      String? capturedAuthHeader;
      final mockClient = MockClient((request) async {
        capturedAuthHeader = request.headers['Authorization'];
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      });

      final api = ApiClient(httpClient: mockClient);
      await api.setTokens(
        token: 'secret_jwt_token_xyz',
        refreshToken: 'refresh_xyz',
      );

      await api.get('/workout-plans');
      expect(capturedAuthHeader, equals('Bearer secret_jwt_token_xyz'));
    });

    test('Throws UnauthorizedException on 401 when token refresh fails', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'error': 'Unauthorized'}), 401);
      });

      final api = ApiClient(httpClient: mockClient);
      await api.setTokens(token: 'expired_token', refreshToken: 'invalid_refresh');

      expect(
        () async => await api.get('/workout-plans'),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('Normalizes endpoints to include /api without duplication', () async {
      Uri? capturedUri;
      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        return http.Response('[]', 200);
      });

      final api = ApiClient(httpClient: mockClient);

      await api.get('/exercises');
      expect(capturedUri.toString(), equals('http://13.140.58.252:22658/api/exercises'));

      await api.get('/api/exercises');
      expect(capturedUri.toString(), equals('http://13.140.58.252:22658/api/exercises'));
    });
  });

  group('AuthService with REST API Tests', () {
    test('Registers user at /api/auth/register and persists access token', () async {
      String? requestPath;
      final mockClient = MockClient((request) async {
        requestPath = request.url.path;
        if (request.url.path == '/api/auth/register') {
          return http.Response(
            jsonEncode({
              'token': 'jwt_access_alpha',
              'refreshToken': 'jwt_refresh_alpha',
              'user': {
                'id': 'athlete_uuid_1',
                'name': 'Alex Strong',
                'email': 'alex@liftlog.test',
                'avatarUrl': '',
                'fitnessGoal': 'Build Strength & Muscle',
                'createdAt': DateTime.now().toIso8601String(),
              },
            }),
            201,
          );
        }
        return http.Response('Not Found', 404);
      });

      final api = ApiClient(httpClient: mockClient);
      final authService = AuthService(api);

      final user = await authService.register(
        name: 'Alex Strong',
        email: 'alex@liftlog.test',
        password: 'SecurePassword123!',
      );

      expect(requestPath, equals('/api/auth/register'));
      expect(user.id, equals('athlete_uuid_1'));
      expect(user.name, equals('Alex Strong'));
      expect(await api.getAccessToken(), equals('jwt_access_alpha'));
      expect(await api.getActiveUserId(), equals('athlete_uuid_1'));
    });

    test('Logins user at /api/auth/login and persists access token', () async {
      String? requestPath;
      final mockClient = MockClient((request) async {
        requestPath = request.url.path;
        if (request.url.path == '/api/auth/login') {
          return http.Response(
            jsonEncode({
              'token': 'jwt_login_token',
              'refreshToken': 'jwt_refresh_token',
              'user': {
                'id': 'athlete_uuid_login',
                'name': 'Athlete Beta',
                'email': 'beta@liftlog.test',
                'avatarUrl': '',
                'fitnessGoal': 'Build Strength & Muscle',
                'createdAt': DateTime.now().toIso8601String(),
              },
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final api = ApiClient(httpClient: mockClient);
      final authService = AuthService(api);

      final user = await authService.login(
        email: 'beta@liftlog.test',
        password: 'Password123!',
      );

      expect(requestPath, equals('/api/auth/login'));
      expect(user.id, equals('athlete_uuid_login'));
      expect(await api.getAccessToken(), equals('jwt_login_token'));
    });

    test('Gets current user at /api/auth/me', () async {
      String? requestPath;
      String? authHeader;
      final mockClient = MockClient((request) async {
        requestPath = request.url.path;
        authHeader = request.headers['Authorization'];
        if (request.url.path == '/api/auth/me') {
          return http.Response(
            jsonEncode({
              'user': {
                'id': 'athlete_uuid_me',
                'name': 'Athlete Me',
                'email': 'me@liftlog.test',
                'avatarUrl': 'https://example.com/pic.png',
                'fitnessGoal': 'Weight Loss',
                'createdAt': DateTime.now().toIso8601String(),
              },
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final api = ApiClient(httpClient: mockClient);
      await api.setTokens(token: 'existing_valid_token', refreshToken: 'existing_refresh');
      final authService = AuthService(api);

      final user = await authService.getCurrentUser();
      expect(requestPath, equals('/api/auth/me'));
      expect(authHeader, equals('Bearer existing_valid_token'));
      expect(user, isNotNull);
      expect(user!.id, equals('athlete_uuid_me'));
      expect(user.email, equals('me@liftlog.test'));
    });

    test('Logs out user at /api/auth/logout and clears tokens', () async {
      String? requestPath;
      final mockClient = MockClient((request) async {
        requestPath = request.url.path;
        return http.Response(jsonEncode({'message': 'Successfully logged out.'}), 200);
      });

      final api = ApiClient(httpClient: mockClient);
      await api.setTokens(token: 'active_token', refreshToken: 'active_refresh', userId: 'user_1');
      final authService = AuthService(api);

      await authService.logout();
      expect(requestPath, equals('/api/auth/logout'));
      expect(await api.getAccessToken(), isNull);
      expect(await api.getActiveUserId(), isNull);
    });
  });

  group('WorkoutPlanRepository REST Integration Tests', () {
    test('Fetches workout plans and deserializes correctly', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/workout-plans')) {
          return http.Response(
            jsonEncode([
              {
                'id': 'plan_01',
                'name': 'Push Hypertrophy',
                'description': 'Chest, Shoulders, Triceps',
                'color_index': 1,
                'days_of_week': [0, 3], // Mon, Thu
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
                'exercises': [
                  {
                    'id': 'pe_01',
                    'plan_id': 'plan_01',
                    'exercise_id': 'bench-press',
                    'exercise_name': 'Barbell Bench Press',
                    'exercise_muscle': 'chest',
                    'exercise_type': 'strength',
                    'sort_order': 0,
                    'target_sets': 4,
                    'target_reps': 8,
                    'target_weight': 80.0,
                    'target_duration_seconds': 0,
                    'rest_seconds': 90,
                  }
                ],
              }
            ]),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final api = ApiClient(httpClient: mockClient);
      final repo = WorkoutPlanRepository(api);

      final plans = await repo.getPlans();
      expect(plans.length, equals(1));
      expect(plans.first.id, equals('plan_01'));
      expect(plans.first.name, equals('Push Hypertrophy'));
      expect(plans.first.exercises.length, equals(1));
      expect(plans.first.exercises.first.exerciseName, equals('Barbell Bench Press'));
      expect(plans.first.exercises.first.targetWeight, equals(80.0));
    });

    test('Returns empty list when user has no plans ("No workout plans yet")', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode([]), 200);
      });

      final api = ApiClient(httpClient: mockClient);
      final repo = WorkoutPlanRepository(api);

      final plans = await repo.getPlans();
      expect(plans, isEmpty);
    });
  });

  group('Domain Model Computations', () {
    test('WorkoutSession computes total volume and reps accurately', () {
      final session = WorkoutSession(
        id: 'sess_1',
        planName: 'Upper Test',
        startedAt: DateTime.now(),
        logs: [
          ExerciseLog(
            id: 'log_1',
            sessionId: 'sess_1',
            exerciseId: 'bench',
            exerciseName: 'Bench Press',
            exerciseType: ExerciseType.strength,
            sortOrder: 0,
            sets: const [
              SetLog(
                id: 's1',
                exerciseLogId: 'log_1',
                setNumber: 1,
                weightKg: 80,
                reps: 10,
                completed: true,
              ),
              SetLog(
                id: 's2',
                exerciseLogId: 'log_1',
                setNumber: 2,
                weightKg: 85,
                reps: 8,
                completed: true,
              ),
            ],
          ),
        ],
      );

      // Volume: 80*10 + 85*8 = 800 + 680 = 1480
      expect(session.totalVolume, equals(1480.0));
      expect(session.totalReps, equals(18));
      expect(session.completedSets, equals(2));
    });

    test('Duration, cardio, distance, and repsOnly exercises have 0.0 volume', () {
      final session = WorkoutSession(
        id: 'sess_cardio',
        planName: 'Cardio & Core',
        startedAt: DateTime.now(),
        logs: [
          ExerciseLog(
            id: 'log_plank',
            sessionId: 'sess_cardio',
            exerciseId: 'plank',
            exerciseName: 'Plank',
            exerciseType: ExerciseType.duration,
            sortOrder: 0,
            sets: const [
              SetLog(
                id: 's1',
                exerciseLogId: 'log_plank',
                setNumber: 1,
                weightKg: 55, // e.g. duration stored or mistakenly passed
                reps: 15,
                durationSeconds: 60,
                completed: true,
              ),
            ],
          ),
          ExerciseLog(
            id: 'log_run',
            sessionId: 'sess_cardio',
            exerciseId: 'treadmill',
            exerciseName: 'Treadmill Run',
            exerciseType: ExerciseType.cardio,
            sortOrder: 1,
            sets: const [
              SetLog(
                id: 's2',
                exerciseLogId: 'log_run',
                setNumber: 1,
                weightKg: 20,
                reps: 5,
                distanceKm: 3.0,
                completed: true,
              ),
            ],
          ),
        ],
      );

      // Volume must strictly be 0.0 for duration and cardio, avoiding the 825 kg bug
      expect(session.logs[0].totalVolume, equals(0.0));
      expect(session.logs[1].totalVolume, equals(0.0));
      expect(session.totalVolume, equals(0.0));
    });

    test('PersonalRecord serializes and parses properly', () {
      final pr = PersonalRecord(
        id: 'pr_1',
        exerciseId: 'bench-press',
        exerciseName: 'Barbell Bench Press',
        recordType: PRType.highestWeight,
        value: 100.0,
        sessionId: 'sess_1',
        achievedAt: DateTime(2026, 3, 1),
      );

      final map = pr.toMap();
      expect(map['value'], equals(100.0));
      expect(map['record_type'], equals('highestWeight'));

      final fromMap = PersonalRecord.fromMap(map);
      expect(fromMap.value, equals(100.0));
      expect(fromMap.recordType, equals(PRType.highestWeight));
    });
  });

  group('UserProfileRepository Tests', () {
    test('saveProfile sends PUT /api/users/profile with updated fields', () async {
      String? capturedPath;
      Map<String, dynamic>? capturedBody;
      final mockClient = MockClient((request) async {
        capturedPath = request.url.path;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'user': {
              'id': 'user_abc',
              'name': 'Updated Name',
              'avatarUrl': 'https://example.com/new.png',
              'fitnessGoal': 'Strength',
            },
          }),
          200,
        );
      });

      final api = ApiClient(httpClient: mockClient);
      final repo = UserProfileRepository(api);

      final profile = UserProfile(
        id: 'user_abc',
        email: 'user@test.com',
        name: 'Updated Name',
        avatarUrl: 'https://example.com/new.png',
        fitnessGoal: 'Strength',
        createdAt: DateTime(2026, 1, 1),
      );

      await repo.saveProfile(profile);
      expect(capturedPath, equals('/api/users/profile'));
      expect(capturedBody?['name'], equals('Updated Name'));
      expect(capturedBody?['avatar_url'], equals('https://example.com/new.png'));
      expect(capturedBody?['fitness_goal'], equals('Strength'));
    });

    test('uploadAvatar sends multipart POST to /api/users/avatar and returns avatar_url', () async {
      String? capturedPath;
      String? capturedContentType;
      final mockClient = MockClient((request) async {
        capturedPath = request.url.path;
        capturedContentType = request.headers['content-type'];
        if (request.url.path == '/api/users/avatar') {
          return http.Response(
            jsonEncode({
              'avatar_url': 'http://13.140.58.252:22658/uploads/avatars/athlete_123.png',
              'user': {
                'id': 'athlete_123',
                'avatarUrl': 'http://13.140.58.252:22658/uploads/avatars/athlete_123.png',
              },
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final api = ApiClient(httpClient: mockClient);
      final repo = UserProfileRepository(api);

      final tempDir = await Directory.systemTemp.createTemp('avatar_test');
      final testFile = File('${tempDir.path}/test_avatar.png');
      await testFile.writeAsBytes([137, 80, 78, 71, 13, 10, 26, 10]);

      try {
        final resultUrl = await repo.uploadAvatar(testFile);
        expect(capturedPath, equals('/api/users/avatar'));
        expect(capturedContentType, contains('multipart/form-data'));
        expect(resultUrl, equals('http://13.140.58.252:22658/uploads/avatars/athlete_123.png'));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });

  group('Day-Wise Workout Plan and Exercise Type-Specific Fields Tests', () {
    test('targetSummary formats duration exercises with sets and duration only (no reps)', () {
      const ex = PlanExercise(
        id: 'ex-1',
        planId: 'plan-1',
        exerciseId: 'plank',
        exerciseName: 'Plank',
        exerciseMuscle: MuscleGroup.core,
        exerciseType: ExerciseType.duration,
        sortOrder: 0,
        targetSets: 3,
        targetReps: 0,
        targetDurationSeconds: 60,
      );

      expect(ex.targetSummary, equals('3 sets × 1m'));
      expect(ex.targetSummary.contains('reps'), isFalse);
    });

    test('targetSummary formats cardio / distance exercises with sets, distance, and duration', () {
      const ex = PlanExercise(
        id: 'ex-2',
        planId: 'plan-1',
        exerciseId: 'treadmill',
        exerciseName: 'Running',
        exerciseMuscle: MuscleGroup.cardio,
        exerciseType: ExerciseType.distance,
        sortOrder: 1,
        targetSets: 1,
        targetReps: 0,
        targetDistanceKm: 5.0,
        targetDurationSeconds: 1500,
      );

      expect(ex.targetSummary, equals('1 sets × 5 km · 25m'));
      expect(ex.targetSummary.contains('reps'), isFalse);
    });

    test('targetSummary formats pure cardio exercises with duration only', () {
      const ex = PlanExercise(
        id: 'ex-cardio-pure',
        planId: 'plan-1',
        exerciseId: 'jump-rope',
        exerciseName: 'Jump Rope',
        exerciseMuscle: MuscleGroup.cardio,
        exerciseType: ExerciseType.cardio,
        sortOrder: 1,
        targetSets: 3,
        targetReps: 0,
        targetDurationSeconds: 600,
      );

      expect(ex.targetSummary, equals('3 sets × 10m'));
      expect(ex.targetSummary.contains('reps'), isFalse);
      expect(ex.targetSummary.contains('km'), isFalse);
    });

    test('targetSummary formats strength exercises with sets and reps', () {
      const ex = PlanExercise(
        id: 'ex-3',
        planId: 'plan-1',
        exerciseId: 'bench-press',
        exerciseName: 'Bench Press',
        exerciseMuscle: MuscleGroup.chest,
        exerciseType: ExerciseType.strength,
        sortOrder: 0,
        targetSets: 4,
        targetReps: 8,
      );

      expect(ex.targetSummary, equals('4 sets × 8 reps'));
    });

    test('WorkoutPlan getExercisesForDay isolates exercises per day when dayOfWeek is specified', () {
      final now = DateTime.now();
      final plan = WorkoutPlan(
        id: 'plan-weekly',
        name: 'Upper / Lower Split',
        description: 'Monday Upper, Tuesday Lower',
        daysOfWeek: [0, 1], // Monday = 0, Tuesday = 1
        createdAt: now,
        updatedAt: now,
        exercises: [
          const PlanExercise(
            id: 'ex-mon-1',
            planId: 'plan-weekly',
            exerciseId: 'chest-press',
            exerciseName: 'Chest Press',
            exerciseMuscle: MuscleGroup.chest,
            exerciseType: ExerciseType.strength,
            sortOrder: 0,
            dayOfWeek: 0,
          ),
          const PlanExercise(
            id: 'ex-mon-2',
            planId: 'plan-weekly',
            exerciseId: 'incline-dumbbell',
            exerciseName: 'Incline DB',
            exerciseMuscle: MuscleGroup.chest,
            exerciseType: ExerciseType.strength,
            sortOrder: 1,
            dayOfWeek: 0,
          ),
          const PlanExercise(
            id: 'ex-tue-1',
            planId: 'plan-weekly',
            exerciseId: 'squat',
            exerciseName: 'Barbell Squat',
            exerciseMuscle: MuscleGroup.legs,
            exerciseType: ExerciseType.strength,
            sortOrder: 0,
            dayOfWeek: 1,
          ),
        ],
      );

      expect(plan.hasDayWiseConfiguration, isTrue);

      final mondayExercises = plan.getExercisesForDay(0);
      expect(mondayExercises.length, equals(2));
      expect(mondayExercises[0].exerciseName, equals('Chest Press'));
      expect(mondayExercises[1].exerciseName, equals('Incline DB'));

      final tuesdayExercises = plan.getExercisesForDay(1);
      expect(tuesdayExercises.length, equals(1));
      expect(tuesdayExercises[0].exerciseName, equals('Barbell Squat'));

      final wednesdayExercises = plan.getExercisesForDay(2);
      expect(wednesdayExercises.isEmpty, isTrue);
    });

    test('WorkoutPlan getExercisesForDay falls back to all exercises for legacy plans without day tags', () {
      final now = DateTime.now();
      final legacyPlan = WorkoutPlan(
        id: 'plan-legacy',
        name: 'Legacy 3-Day Plan',
        description: '',
        daysOfWeek: [0, 2, 4],
        createdAt: now,
        updatedAt: now,
        exercises: [
          const PlanExercise(
            id: 'ex-1',
            planId: 'plan-legacy',
            exerciseId: 'squat',
            exerciseName: 'Squat',
            exerciseMuscle: MuscleGroup.legs,
            exerciseType: ExerciseType.strength,
            sortOrder: 0,
            dayOfWeek: null,
          ),
        ],
      );

      expect(legacyPlan.hasDayWiseConfiguration, isFalse);

      final monExercises = legacyPlan.getExercisesForDay(0);
      expect(monExercises.length, equals(1));
      expect(monExercises[0].exerciseName, equals('Squat'));

      final restExercises = legacyPlan.getExercisesForDay(1);
      expect(restExercises.isEmpty, isTrue);
    });

    test('PlanExercise toMap and fromMap preserve dayOfWeek and targetDistanceKm', () {
      const original = PlanExercise(
        id: 'ex-roundtrip',
        planId: 'plan-1',
        exerciseId: 'run',
        exerciseName: 'Running',
        exerciseMuscle: MuscleGroup.cardio,
        exerciseType: ExerciseType.distance,
        sortOrder: 2,
        dayOfWeek: 3,
        targetSets: 1,
        targetReps: 0,
        targetDurationSeconds: 1200,
        targetDistanceKm: 3.5,
      );

      final map = original.toMap();
      expect(map['day_of_week'], equals(3));
      expect(map['target_distance_km'], equals(3.5));

      final restored = PlanExercise.fromMap(map);
      expect(restored.id, equals(original.id));
      expect(restored.dayOfWeek, equals(3));
      expect(restored.targetDistanceKm, equals(3.5));
      expect(restored.targetDurationSeconds, equals(1200));
    });
  });
}
