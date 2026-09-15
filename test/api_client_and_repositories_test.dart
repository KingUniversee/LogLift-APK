import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:liftlog/core/network/api_client.dart';
import 'package:liftlog/data/models/exercise.dart';
import 'package:liftlog/data/models/personal_record.dart';
import 'package:liftlog/data/models/workout_session.dart';
import 'package:liftlog/data/repositories/workout_plan_repository.dart';
import 'package:liftlog/data/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
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
  });

  group('AuthService with REST API Tests', () {
    test('Registers user and persists access token', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/register')) {
          return http.Response(
            jsonEncode({
              'token': 'jwt_access_alpha',
              'refreshToken': 'jwt_refresh_alpha',
              'user': {
                'id': 'athlete_uuid_1',
                'name': 'Alex Strong',
                'email': 'alex@liftlog.test',
                'avatar_url': '',
                'fitness_goal': 'Build Strength & Muscle',
                'created_at': DateTime.now().toIso8601String(),
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

      expect(user.id, equals('athlete_uuid_1'));
      expect(user.name, equals('Alex Strong'));
      expect(await api.getAccessToken(), equals('jwt_access_alpha'));
      expect(await api.getActiveUserId(), equals('athlete_uuid_1'));
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
}
