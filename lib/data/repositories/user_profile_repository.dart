import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/user_profile.dart';

class UserProfileRepository {
  UserProfileRepository([Database? db]) : _db = db;
  final Database? _db;

  Future<Database> get _database async => _db ?? await AppDatabase.instance.database;

  Future<UserProfile?> getProfile() async {
    final db = await _database;
    final maps = await db.query('user_profile', limit: 1);
    if (maps.isEmpty) return null;
    return UserProfile.fromMap(maps.first);
  }

  Future<void> saveProfile(UserProfile profile) async {
    final db = await _database;
    await db.insert(
      'user_profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
