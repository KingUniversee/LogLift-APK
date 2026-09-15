import '../../core/network/api_client.dart';
import '../models/personal_record.dart';

class PersonalRecordRepository {
  PersonalRecordRepository([ApiClient? api]) : _api = api ?? ApiClient.instance;
  final ApiClient _api;

  Future<List<PersonalRecord>> getAllPRs() async {
    final response = await _api.get('/personal-records');
    if (response is List) {
      return response
          .map((d) => PersonalRecord.fromMap(Map<String, dynamic>.from(d as Map)))
          .toList();
    }
    return [];
  }

  Future<List<PersonalRecord>> getPRsForExercise(String exerciseId) async {
    final response = await _api.get(
      '/personal-records',
      queryParams: {'exerciseId': exerciseId},
    );
    if (response is List) {
      return response
          .map((d) => PersonalRecord.fromMap(Map<String, dynamic>.from(d as Map)))
          .toList();
    }
    return [];
  }

  Future<PersonalRecord?> getBestRecord(String exerciseId, PRType recordType) async {
    try {
      final response = await _api.get(
        '/personal-records',
        queryParams: {
          'exerciseId': exerciseId,
          'recordType': recordType.name,
          'best': 'true',
        },
      );
      if (response is Map<String, dynamic>) {
        return PersonalRecord.fromMap(response);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> savePR(PersonalRecord pr) async {
    await _api.post('/personal-records', body: pr.toMap());
  }

  Future<void> deletePRsForSession(String sessionId) async {
    await _api.delete('/personal-records/session/$sessionId');
  }
}
