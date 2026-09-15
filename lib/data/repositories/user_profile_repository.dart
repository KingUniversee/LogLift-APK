import 'package:mongo_dart/mongo_dart.dart';
import '../database/mongo_database.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

class UserProfileRepository {
  UserProfileRepository([MongoDatabase? db, AuthService? authService])
      : _db = db ?? MongoDatabase.instance,
        _authService = authService ?? AuthService();

  final MongoDatabase _db;
  final AuthService _authService;

  Future<UserProfile?> getProfile() async {
    return _authService.getCurrentUser();
  }

  Future<void> saveProfile(UserProfile profile) async {
    final users = await _db.usersCollection;
    await users.replaceOne(
      where.eq('id', profile.id),
      profile.toMap()..['_id'] = profile.id,
      upsert: true,
    );
  }
}
