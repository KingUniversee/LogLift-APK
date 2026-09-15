import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../database/mongo_database.dart';
import '../models/user_profile.dart';

class AuthService {
  AuthService([MongoDatabase? db]) : _db = db ?? MongoDatabase.instance;
  final MongoDatabase _db;

  static const _prefKeyUserId = 'liftlog_active_user_id';

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$password::$salt');
    return sha256.convert(bytes).toString();
  }

  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final users = await _db.usersCollection;

    final existing = await users.findOne(where.eq('email', normalizedEmail));
    if (existing != null) {
      throw Exception('An account with this email already exists.');
    }

    final userId = const Uuid().v4();
    final salt = const Uuid().v4();
    final passwordHash = _hashPassword(password, salt);
    final now = DateTime.now();

    final userDoc = {
      '_id': userId,
      'id': userId,
      'name': name.trim(),
      'email': normalizedEmail,
      'password_hash': passwordHash,
      'salt': salt,
      'avatar_url': '',
      'fitness_goal': 'Build Strength & Muscle',
      'created_at': now.toIso8601String(),
    };

    await users.insertOne(userDoc);

    // Persist session
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyUserId, userId);

    return UserProfile.fromMap(userDoc);
  }

  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final users = await _db.usersCollection;

    final userDoc = await users.findOne(where.eq('email', normalizedEmail));
    if (userDoc == null) {
      throw Exception('No account found with this email.');
    }

    final salt = userDoc['salt'] as String? ?? '';
    final storedHash = userDoc['password_hash'] as String? ?? '';
    final computedHash = _hashPassword(password, salt);

    if (computedHash != storedHash) {
      throw Exception('Incorrect password. Please try again.');
    }

    final userId = userDoc['id'] as String? ?? userDoc['_id'].toString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyUserId, userId);

    return UserProfile.fromMap(userDoc);
  }

  Future<UserProfile?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_prefKeyUserId);
    if (userId == null || userId.isEmpty) return null;

    try {
      final users = await _db.usersCollection;
      final doc = await users.findOne(where.eq('id', userId));
      if (doc == null) return null;
      return UserProfile.fromMap(doc);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyUserId);
  }
}
