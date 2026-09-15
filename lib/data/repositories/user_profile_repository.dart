import '../../core/network/api_client.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

class UserProfileRepository {
  UserProfileRepository([ApiClient? api, AuthService? authService])
      : _api = api ?? ApiClient.instance,
        _authService = authService ?? AuthService();

  final ApiClient _api;
  final AuthService _authService;

  Future<UserProfile?> getProfile() async {
    return _authService.getCurrentUser();
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _api.put(
      '/users/profile',
      body: {
        'name': profile.name,
        'avatar_url': profile.avatarUrl,
        'fitness_goal': profile.fitnessGoal,
      },
    );
  }
}
