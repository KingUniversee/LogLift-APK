import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import '../database/mongo_database.dart';
import '../models/app_settings.dart';

class SettingsRepository {
  SettingsRepository([MongoDatabase? db]) : _db = db ?? MongoDatabase.instance;
  final MongoDatabase _db;

  Future<AppSettings> getSettings() async {
    final collection = await _db.settingsCollection;
    final doc = await collection.findOne(where.eq('id', 'settings_default'));
    if (doc == null) return const AppSettings();
    return AppSettings.fromMap(doc);
  }

  Future<void> saveSettings(AppSettings settings) async {
    final collection = await _db.settingsCollection;
    final doc = settings.toMap()..['_id'] = 'settings_default';
    await collection.replaceOne(
      where.eq('id', 'settings_default'),
      doc,
      upsert: true,
    );
  }

  Future<String> exportAllDataAsJson() async {
    final exercises = await (await _db.exercisesCollection).find().toList();
    final plans = await (await _db.plansCollection).find().toList();
    final sessions = await (await _db.sessionsCollection).find().toList();
    final prs = await (await _db.prsCollection).find().toList();
    final settings = await (await _db.settingsCollection).find().toList();
    final users = await (await _db.usersCollection).find().toList();

    final exportMap = {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'users': users,
      'exercises': exercises,
      'workout_plans': plans,
      'workout_sessions': sessions,
      'personal_records': prs,
      'app_settings': settings,
    };

    return jsonEncode(exportMap);
  }

  Future<bool> importDataFromJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      if (data['exercises'] is List) {
        final col = await _db.exercisesCollection;
        for (final row in data['exercises'] as List) {
          final m = Map<String, dynamic>.from(row as Map);
          await col.replaceOne(where.eq('id', m['id']), m, upsert: true);
        }
      }
      if (data['workout_plans'] is List) {
        final col = await _db.plansCollection;
        for (final row in data['workout_plans'] as List) {
          final m = Map<String, dynamic>.from(row as Map);
          await col.replaceOne(where.eq('id', m['id']), m, upsert: true);
        }
      }
      if (data['workout_sessions'] is List) {
        final col = await _db.sessionsCollection;
        for (final row in data['workout_sessions'] as List) {
          final m = Map<String, dynamic>.from(row as Map);
          await col.replaceOne(where.eq('id', m['id']), m, upsert: true);
        }
      }
      if (data['personal_records'] is List) {
        final col = await _db.prsCollection;
        for (final row in data['personal_records'] as List) {
          final m = Map<String, dynamic>.from(row as Map);
          await col.replaceOne(where.eq('id', m['id']), m, upsert: true);
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteAllData() async {
    await _db.clearAllData();
  }
}
