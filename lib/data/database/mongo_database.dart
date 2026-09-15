import 'dart:developer' as developer;
import 'package:mongo_dart/mongo_dart.dart';

class MongoDatabase {
  MongoDatabase._();
  static final MongoDatabase instance = MongoDatabase._();

  static const String connectionUri =
      'mongodb+srv://dsxseco_db_user:TecVweQo7K6F2AU7@liftlog.iwf8yy7.mongodb.net/liftlog?retryWrites=true&w=majority';

  Db? _db;
  bool _isConnecting = false;

  bool get isConnected => _db != null && _db!.isConnected;

  Future<Db> get db async {
    if (_db != null && _db!.isConnected) return _db!;
    try {
      await connect();
    } catch (_) {
      _db ??= await Db.create(connectionUri);
    }
    return _db!;
  }

  Future<void> connect() async {
    if (_isConnecting) return;
    _isConnecting = true;

    try {
      _db ??= await Db.create(connectionUri);

      if (!_db!.isConnected) {
        developer.log('Connecting to MongoDB Atlas...', name: 'MongoDatabase');
        await _db!.open();
        developer.log('Connected to MongoDB Atlas successfully.', name: 'MongoDatabase');
      }
    } catch (e, stack) {
      developer.log('Failed to connect to MongoDB Atlas: $e', name: 'MongoDatabase', error: e, stackTrace: stack);
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> close() async {
    if (_db != null && _db!.isConnected) {
      await _db!.close();
      _db = null;
    }
  }

  // Collections
  Future<DbCollection> get usersCollection async => (await db).collection('users');
  Future<DbCollection> get exercisesCollection async => (await db).collection('exercises');
  Future<DbCollection> get plansCollection async => (await db).collection('workout_plans');
  Future<DbCollection> get sessionsCollection async => (await db).collection('workout_sessions');
  Future<DbCollection> get prsCollection async => (await db).collection('personal_records');
  Future<DbCollection> get settingsCollection async => (await db).collection('app_settings');

  Future<void> clearAllData() async {
    final d = await db;
    await d.collection('exercises').deleteMany(where);
    await d.collection('workout_plans').deleteMany(where);
    await d.collection('workout_sessions').deleteMany(where);
    await d.collection('personal_records').deleteMany(where);
    await d.collection('app_settings').deleteMany(where);
    await d.collection('users').deleteMany(where);
  }
}
