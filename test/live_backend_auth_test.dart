// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlog/core/network/api_client.dart';
import 'package:liftlog/core/network/api_config.dart';
import 'package:liftlog/data/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Live Deployed Backend Auth Integration Tests', () {
    test('Register, Get Current User, Login, and Logout against live backend', () async {
      // Ensure ApiConfig points to deployed backend
      expect(ApiConfig.baseUrl, equals('http://13.140.58.252:22658'));

      final api = ApiClient();
      final authService = AuthService(api);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final testEmail = 'athlete_live_$timestamp@liftlog.test';
      const testPassword = 'LivePassword123!';
      const testName = 'Live Verification Athlete';

      // 1. POST /api/auth/register
      print('Testing live registration for: $testEmail');
      final registeredUser = await authService.register(
        name: testName,
        email: testEmail,
        password: testPassword,
      );

      expect(registeredUser.id, isNotEmpty);
      expect(registeredUser.email, equals(testEmail));
      expect(registeredUser.name, equals(testName));

      // Verify token persistence
      final savedToken = await api.getAccessToken();
      final savedRefreshToken = await api.getRefreshToken();
      final savedUserId = await api.getActiveUserId();

      expect(savedToken, isNotNull);
      expect(savedToken, isNotEmpty);
      expect(savedRefreshToken, isNotNull);
      expect(savedRefreshToken, isNotEmpty);
      expect(savedUserId, equals(registeredUser.id));
      print('Live registration succeeded. Token saved in local storage.');

      // 2. GET /api/auth/me (validates current user / session)
      final currentUser = await authService.getCurrentUser();
      expect(currentUser, isNotNull);
      expect(currentUser!.id, equals(registeredUser.id));
      expect(currentUser.email, equals(testEmail));
      print('Live session check (GET /api/auth/me) verified user profile.');

      // 3. Clear local tokens to simulate clean re-login
      await api.clearTokens();
      expect(await api.getAccessToken(), isNull);

      // 4. POST /api/auth/login
      print('Testing live login for: $testEmail');
      final loggedInUser = await authService.login(
        email: testEmail,
        password: testPassword,
      );

      expect(loggedInUser.id, equals(registeredUser.id));
      expect(loggedInUser.email, equals(testEmail));

      final loginToken = await api.getAccessToken();
      expect(loginToken, isNotNull);
      expect(loginToken, isNotEmpty);
      print('Live login succeeded. New session token persisted.');

      // 5. POST /api/auth/logout
      print('Testing live logout...');
      await authService.logout();

      final postLogoutToken = await api.getAccessToken();
      final postLogoutUserId = await api.getActiveUserId();
      expect(postLogoutToken, isNull);
      expect(postLogoutUserId, isNull);

      final afterLogoutUser = await authService.getCurrentUser();
      expect(afterLogoutUser, isNull);
      print('Live logout succeeded. Local session cleared.');
    }, timeout: const Timeout(Duration(seconds: 45)));
  });
}
