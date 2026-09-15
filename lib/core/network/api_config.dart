import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  ApiConfig._();

  static const String _prefKeyCustomBaseUrl = 'liftlog_custom_base_url';
  static String? _cachedCustomBaseUrl;

  static Future<void> loadCustomBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedCustomBaseUrl = prefs.getString(_prefKeyCustomBaseUrl);
    } catch (_) {}
  }

  static Future<void> setCustomBaseUrl(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url == null || url.trim().isEmpty) {
      await prefs.remove(_prefKeyCustomBaseUrl);
      _cachedCustomBaseUrl = null;
    } else {
      var clean = url.trim();
      while (clean.endsWith('/')) {
        clean = clean.substring(0, clean.length - 1);
      }
      if (!clean.endsWith('/api')) {
        clean = '$clean/api';
      }
      await prefs.setString(_prefKeyCustomBaseUrl, clean);
      _cachedCustomBaseUrl = clean;
    }
  }

  /// Current resolved API base URL.
  /// Priority:
  /// 1. Custom URL saved by user in Settings/Network
  /// 2. --dart-define=API_BASE_URL=...
  /// 3. Platform default (10.0.2.2 for Android emulator, localhost for iOS/desktop)
  static String get baseUrl {
    if (_cachedCustomBaseUrl != null && _cachedCustomBaseUrl!.isNotEmpty) {
      return _cachedCustomBaseUrl!;
    }

    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv.endsWith('/') ? fromEnv.substring(0, fromEnv.length - 1) : fromEnv;
    }

    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    }

    return 'http://localhost:5000/api';
  }

  // Google OAuth Web Client ID for LiftLog
  static const String googleClientId =
      '920575978481-a1o52s4mkkoep0te6a8jnho2ves5iqos.apps.googleusercontent.com';
}
