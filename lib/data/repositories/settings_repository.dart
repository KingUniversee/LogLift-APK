import 'dart:convert';
import '../../core/network/api_client.dart';
import '../models/app_settings.dart';

class SettingsRepository {
  SettingsRepository([ApiClient? api]) : _api = api ?? ApiClient.instance;
  final ApiClient _api;

  Future<AppSettings> getSettings() async {
    try {
      final response = await _api.get('/settings');
      if (response is Map<String, dynamic>) {
        return AppSettings.fromMap(response);
      }
      return const AppSettings();
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _api.put('/settings', body: settings.toMap());
  }

  Future<String> exportAllDataAsJson() async {
    final response = await _api.get('/settings/export');
    return jsonEncode(response);
  }

  Future<bool> importDataFromJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString);
      await _api.post('/settings/import', body: data);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteAllData() async {
    await _api.delete('/settings/delete-all');
  }
}
