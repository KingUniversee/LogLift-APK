import 'package:mongo_dart/mongo_dart.dart';
import '../database/mongo_database.dart';
import '../models/personal_record.dart';

class PersonalRecordRepository {
  PersonalRecordRepository([MongoDatabase? db]) : _db = db ?? MongoDatabase.instance;
  final MongoDatabase _db;

  Future<List<PersonalRecord>> getAllPRs() async {
    final collection = await _db.prsCollection;
    final docs = await collection.find(where.sortBy('achieved_at', descending: true)).toList();
    return docs.map((d) => PersonalRecord.fromMap(d)).toList();
  }

  Future<List<PersonalRecord>> getPRsForExercise(String exerciseId) async {
    final collection = await _db.prsCollection;
    final docs = await collection.find(
      where.eq('exercise_id', exerciseId).sortBy('achieved_at', descending: true),
    ).toList();
    return docs.map((d) => PersonalRecord.fromMap(d)).toList();
  }

  Future<PersonalRecord?> getBestRecord(String exerciseId, PRType recordType) async {
    final collection = await _db.prsCollection;
    final doc = await collection.findOne(
      where.eq('exercise_id', exerciseId).eq('record_type', recordType.name).sortBy('value', descending: true),
    );
    if (doc == null) return null;
    return PersonalRecord.fromMap(doc);
  }

  Future<void> savePR(PersonalRecord pr) async {
    final collection = await _db.prsCollection;
    final doc = pr.toMap()..['_id'] = pr.id;
    await collection.replaceOne(
      where.eq('id', pr.id),
      doc,
      upsert: true,
    );
  }

  Future<void> deletePRsForSession(String sessionId) async {
    final collection = await _db.prsCollection;
    await collection.deleteMany(where.eq('session_id', sessionId));
  }
}
