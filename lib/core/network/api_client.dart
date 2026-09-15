import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final dynamic details;

  const ApiException({
    required this.message,
    required this.statusCode,
    this.details,
  });

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    super.message = 'Session expired. Please sign in again.',
    super.statusCode = 401,
  });
}

class NetworkException extends ApiException {
  const NetworkException({
    super.message = 'Network connection unavailable. Please check your connection and ensure the backend server is running.',
    super.statusCode = 0,
  });
}

class ApiClient {
  ApiClient({
    http.Client? httpClient,
    String? baseUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  static final ApiClient instance = ApiClient();

  final http.Client _httpClient;
  final String _baseUrl;

  static const _prefKeyToken = 'liftlog_access_token';
  static const _prefKeyRefreshToken = 'liftlog_refresh_token';
  static const _prefKeyUserId = 'liftlog_active_user_id';

  bool _isRefreshing = false;
  final List<Completer<bool>> _refreshWaiters = [];

  String get baseUrl => _baseUrl;

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKeyToken);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKeyRefreshToken);
  }

  Future<String?> getActiveUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKeyUserId);
  }

  Future<void> setTokens({
    required String token,
    required String refreshToken,
    String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyToken, token);
    await prefs.setString(_prefKeyRefreshToken, refreshToken);
    if (userId != null && userId.isNotEmpty) {
      await prefs.setString(_prefKeyUserId, userId);
    }
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyToken);
    await prefs.remove(_prefKeyRefreshToken);
    await prefs.remove(_prefKeyUserId);
  }

  Future<Map<String, String>> _buildHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = await getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Uri _buildUri(String path, [Map<String, String>? queryParams]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final url = '$_baseUrl$cleanPath';

    if (queryParams == null || queryParams.isEmpty) {
      return Uri.parse(url);
    }

    final filteredParams = <String, String>{};
    queryParams.forEach((key, value) {
      if (value.isNotEmpty) {
        filteredParams[key] = value;
      }
    });

    return Uri.parse(url).replace(queryParameters: filteredParams);
  }

  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool includeAuth = true,
  }) async {
    return _sendWithRetry(
      () async {
        final uri = _buildUri(endpoint, queryParams);
        final headers = await _buildHeaders(includeAuth: includeAuth);
        return _httpClient.get(uri, headers: headers);
      },
      endpoint: endpoint,
    );
  }

  Future<dynamic> post(
    String endpoint, {
    dynamic body,
    bool includeAuth = true,
  }) async {
    return _sendWithRetry(
      () async {
        final uri = _buildUri(endpoint);
        final headers = await _buildHeaders(includeAuth: includeAuth);
        return _httpClient.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      },
      endpoint: endpoint,
    );
  }

  Future<dynamic> put(
    String endpoint, {
    dynamic body,
    bool includeAuth = true,
  }) async {
    return _sendWithRetry(
      () async {
        final uri = _buildUri(endpoint);
        final headers = await _buildHeaders(includeAuth: includeAuth);
        return _httpClient.put(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      },
      endpoint: endpoint,
    );
  }

  Future<dynamic> delete(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    return _sendWithRetry(
      () async {
        final uri = _buildUri(endpoint);
        final headers = await _buildHeaders(includeAuth: includeAuth);
        return _httpClient.delete(uri, headers: headers);
      },
      endpoint: endpoint,
    );
  }

  Future<dynamic> _sendWithRetry(
    Future<http.Response> Function() requestFn, {
    required String endpoint,
  }) async {
    http.Response response;
    try {
      response = await requestFn().timeout(const Duration(seconds: 15));
    } on SocketException catch (_) {
      throw const NetworkException();
    } on TimeoutException catch (_) {
      throw const NetworkException(
        message: 'Connection timed out. Please verify that the LiftLog backend server is running.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException(message: 'Network request failed: $e');
    }

    // Handle 401 Unauthorized by attempting token refresh
    if (response.statusCode == 401 && !endpoint.contains('/auth/')) {
      final refreshed = await _attemptTokenRefresh();
      if (refreshed) {
        try {
          response = await requestFn().timeout(const Duration(seconds: 15));
        } catch (e) {
          throw const NetworkException();
        }
      } else {
        await clearTokens();
        throw const UnauthorizedException();
      }
    }

    return _handleResponse(response);
  }

  Future<bool> _attemptTokenRefresh() async {
    if (_isRefreshing) {
      final completer = Completer<bool>();
      _refreshWaiters.add(completer);
      return completer.future;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _notifyWaiters(false);
        return false;
      }

      final uri = _buildUri('/auth/refresh');
      final res = await _httpClient
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final newToken = data['token'] as String?;
        final newRefreshToken = data['refreshToken'] as String?;

        if (newToken != null && newRefreshToken != null) {
          await setTokens(token: newToken, refreshToken: newRefreshToken);
          _notifyWaiters(true);
          return true;
        }
      }

      _notifyWaiters(false);
      return false;
    } catch (_) {
      _notifyWaiters(false);
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  void _notifyWaiters(bool success) {
    for (final waiter in _refreshWaiters) {
      if (!waiter.isCompleted) {
        waiter.complete(success);
      }
    }
    _refreshWaiters.clear();
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 204 || response.body.isEmpty) {
      return null;
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    if (response.statusCode == 401) {
      throw const UnauthorizedException();
    }

    String message = 'API Error (${response.statusCode})';
    if (decoded is Map<String, dynamic> && decoded.containsKey('error')) {
      message = decoded['error'].toString();
    } else if (decoded is String && decoded.isNotEmpty) {
      message = decoded;
    }

    throw ApiException(
      message: message,
      statusCode: response.statusCode,
      details: decoded,
    );
  }
}
