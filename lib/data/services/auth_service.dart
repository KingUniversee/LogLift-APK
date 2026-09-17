import '../../core/network/api_client.dart';
import '../models/user_profile.dart';

class AuthService {
  AuthService([ApiClient? apiClient]) : _api = apiClient ?? ApiClient.instance;
  final ApiClient _api;

  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      '/api/auth/register',
      body: {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      },
      includeAuth: false,
    );

    if (response is Map<String, dynamic>) {
      final token = response['token'] as String;
      final refreshToken = response['refreshToken'] as String;
      final userMap = Map<String, dynamic>.from(response['user'] as Map);
      final user = UserProfile.fromMap(userMap);

      await _api.setTokens(
        token: token,
        refreshToken: refreshToken,
        userId: user.id,
      );

      return user;
    }

    throw const ApiException(
      message: 'Unexpected server response during registration.',
      statusCode: 500,
    );
  }

  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      '/api/auth/login',
      body: {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
      includeAuth: false,
    );

    if (response is Map<String, dynamic>) {
      final token = response['token'] as String;
      final refreshToken = response['refreshToken'] as String;
      final userMap = Map<String, dynamic>.from(response['user'] as Map);
      final user = UserProfile.fromMap(userMap);

      await _api.setTokens(
        token: token,
        refreshToken: refreshToken,
        userId: user.id,
      );

      return user;
    }

    throw const ApiException(
      message: 'Unexpected server response during login.',
      statusCode: 500,
    );
  }

  Future<UserProfile?> getCurrentUser() async {
    final token = await _api.getAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final response = await _api.get('/api/auth/me');
      if (response is Map<String, dynamic> && response.containsKey('user')) {
        final userMap = Map<String, dynamic>.from(response['user'] as Map);
        return UserProfile.fromMap(userMap);
      }
      return null;
    } catch (e) {
      if (e is UnauthorizedException) {
        await _api.clearTokens();
        return null;
      }
      // On network or unexpected errors, rethrow so caller handles connection failure
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/api/auth/logout');
    } catch (_) {
      // Ignored if offline or expired
    } finally {
      await _api.clearTokens();
    }
  }
}
