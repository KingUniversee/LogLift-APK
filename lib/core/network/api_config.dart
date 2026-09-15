import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  /// Default API base URL configured via --dart-define=API_BASE_URL=...
  /// Defaults to localhost for iOS/Desktop and 10.0.2.2 for Android emulator.
  static String get baseUrl {
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
