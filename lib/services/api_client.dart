import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({http.Client? httpClient, String? baseUrl, String? token})
      : _http = httpClient ?? http.Client(),
        _baseUrl = _normalizeBaseUrl(baseUrl ?? 'http://localhost:8080'),
        _token = token;

  final http.Client _http;
  final String _baseUrl;
  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final root = _baseUrl.endsWith('/') ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$root$p').replace(queryParameters: query);
  }

  static String _normalizeBaseUrl(String url) {
    var u = url.trim();
    if (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  Map<String, String> _headers({Map<String, String>? extra}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    if (extra != null) headers.addAll(extra);
    return headers;
  }

  static const Duration _timeout = Duration(seconds: 15);

  Future<dynamic> get(String path, {Map<String, dynamic>? query, Duration? timeout}) async {
    try {
      final res = await _http
          .get(_uri(path, query), headers: _headers())
          .timeout(timeout ?? _timeout);
      return _handleResponse(res);
    } on TimeoutException catch (_) {
      throw ApiException(408, 'Yêu cầu quá thời gian. Vui lòng thử lại.');
    }
  }

  Future<dynamic> post(String path, {Object? body, Map<String, dynamic>? query, Duration? timeout}) async {
    try {
      final uri = _uri(path, query);
      print('🌐 POST Request');
      print('📍 URL: $uri');
      print('🏠 Base URL: $_baseUrl');
      print('📝 Path: $path');
      
      final res = await _http
          .post(
            uri,
            headers: _headers(),
            body: body is String ? body : jsonEncode(body ?? {}),
          )
          .timeout(timeout ?? _timeout);
      return _handleResponse(res);
    } on TimeoutException catch (_) {
      throw ApiException(408, 'Yêu cầu quá thời gian. Vui lòng thử lại.');
    }
  }

  Future<dynamic> put(String path, {Object? body, Map<String, dynamic>? query, Duration? timeout}) async {
    try {
      final res = await _http
          .put(
            _uri(path, query),
            headers: _headers(),
            body: body is String ? body : jsonEncode(body ?? {}),
          )
          .timeout(timeout ?? _timeout);
      return _handleResponse(res);
    } on TimeoutException catch (_) {
      throw ApiException(408, 'Yêu cầu quá thời gian. Vui lòng thử lại.');
    }
  }

  Future<dynamic> patch(String path, {Object? body, Map<String, dynamic>? query, Duration? timeout}) async {
    try {
      final res = await _http
          .patch(
            _uri(path, query),
            headers: _headers(),
            body: body is String ? body : jsonEncode(body ?? {}),
          )
          .timeout(timeout ?? _timeout);
      return _handleResponse(res);
    } on TimeoutException catch (_) {
      throw ApiException(408, 'Yêu cầu quá thời gian. Vui lòng thử lại.');
    }
  }

  Future<dynamic> delete(String path, {Object? body, Map<String, dynamic>? query, Duration? timeout}) async {
    try {
      final res = await _http
          .delete(
            _uri(path, query),
            headers: _headers(),
            body: body is String ? body : jsonEncode(body ?? {}),
          )
          .timeout(timeout ?? _timeout);
      return _handleResponse(res);
    } on TimeoutException catch (_) {
      throw ApiException(408, 'Yêu cầu quá thời gian. Vui lòng thử lại.');
    }
  }

  dynamic _handleResponse(http.Response res) {
    // Debug prints for easier backend error inspection
    // These help surface exact messages instead of generic status codes
    // Example:
    // 🛰️ STATUS: 400
    // 📦 BODY: {"success":false,"message":"Invalid email or password"}
    // Note: Keep prints lightweight; remove or gate behind a flag for production if needed
    // (Left as-is here to aid debugging during development.)
    //
    // Using print instead of debugPrint to ensure visibility in release logs if needed
    print('🛰️ STATUS: ${res.statusCode}');
    if (res.body.isNotEmpty) {
      print('📦 BODY: ${res.body}');
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      try {
        return jsonDecode(res.body);
      } catch (_) {
        return res.body;
      }
    }
    String message = res.body;
    try {
      final json = jsonDecode(res.body);
      if (json is Map<String, dynamic>) {
        // Common patterns
        // 1) { message: string | [..], error: string, statusCode }
        // 2) { success:false, message:'Validation failed', errors:{ field:[..] } }
        // 3) { errors:[ { field/property, messages/[..] | constraints:{k:v} | message } ] }
        // 4) { details:[..] } or { detail: '..' }

        // Prefer array of messages if provided
        final dynamic msg = json['message'];
        if (msg is List) {
          message = msg.map((e) => e.toString()).join(' | ');
        } else if (msg is String && msg.trim().isNotEmpty) {
          message = msg;
        } else if (json['error'] is String && (json['error'] as String).trim().isNotEmpty) {
          message = json['error'];
        }

        // errors as Map<String, List<String> | String>
        if ((json['errors'] is Map) && (json['errors'] as Map).isNotEmpty) {
          final map = (json['errors'] as Map);
          final parts = <String>[];
          for (final entry in map.entries) {
            final key = entry.key.toString();
            final val = entry.value;
            if (val is List) {
              parts.add('$key: ${val.map((e) => e.toString()).join(', ')}');
            } else if (val is Map) {
              parts.add('$key: ${val.values.map((e) => e.toString()).join(', ')}');
            } else {
              parts.add('$key: ${val.toString()}');
            }
          }
          if (parts.isNotEmpty) message = parts.join(' | ');
        }

        // errors as List<dynamic>
        if (json['errors'] is List && (json['errors'] as List).isNotEmpty) {
          final list = (json['errors'] as List);
          final parts = <String>[];
          for (final item in list) {
            if (item is String) {
              parts.add(item);
            } else if (item is Map) {
              final field = (item['field'] ?? item['property'] ?? item['path'] ?? '').toString();
              final messages = <String>[];
              if (item['messages'] is List) {
                messages.addAll((item['messages'] as List).map((e) => e.toString()));
              }
              if (item['constraints'] is Map) {
                messages.addAll((item['constraints'] as Map).values.map((e) => e.toString()));
              }
              if (item['message'] != null && messages.isEmpty) {
                messages.add(item['message'].toString());
              }
              final combined = messages.isEmpty ? null : messages.join(', ');
              if (combined != null) {
                parts.add(field.isNotEmpty ? '$field: $combined' : combined);
              }
            }
          }
          if (parts.isNotEmpty) message = parts.join(' | ');
        }

        // detail(s)
        if (json['detail'] is String && (json['detail'] as String).trim().isNotEmpty) {
          message = json['detail'];
        }
        if (json['details'] is List && (json['details'] as List).isNotEmpty) {
          message = (json['details'] as List).map((e) => e.toString()).join(' | ');
        }
      }
    } catch (_) {}
    // Normalize noisy auth errors like: "Login failed: Login failed: Bad credentials"
    String normalized = message.trim();
    // Strip any number of case-insensitive "Login failed:" prefixes
    final prefixRegex = RegExp(r'^(login failed:\s*)+', caseSensitive: false);
    normalized = normalized.replaceFirst(prefixRegex, '').trimLeft();
    // Map common 401 credential messages to a clear, friendly text
    if (res.statusCode == 401 || RegExp('bad credentials', caseSensitive: false).hasMatch(normalized)) {
      normalized = 'Email hoặc mật khẩu không đúng';
    }
    // Trim overly long messages
    if (normalized.length > 800) {
      normalized = normalized.substring(0, 800);
    }
    throw ApiException(res.statusCode, normalized.isNotEmpty ? normalized : message);
  }
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.body);
  final int statusCode;
  final String body;
  @override
  String toString() => 'ApiException($statusCode): $body';
}


