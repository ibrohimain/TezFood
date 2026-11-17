import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../ui/session.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required this.baseUrl, required this.session});

  final String baseUrl;
  final SessionModel session;

  Future<dynamic> get(String path, {String auth = 'none', Map<String, String>? query}) {
    return _send('GET', path, auth: auth, query: query);
  }

  Future<dynamic> post(String path, {Object? body, String auth = 'none'}) {
    return _send('POST', path, body: body, auth: auth);
  }

  Future<dynamic> put(String path, {Object? body, String auth = 'admin'}) {
    return _send('PUT', path, body: body, auth: auth);
  }

  Future<dynamic> patch(String path, {Object? body, String auth = 'staff'}) {
    return _send('PATCH', path, body: body, auth: auth);
  }

  Future<dynamic> delete(String path, {String auth = 'admin'}) {
    return _send('DELETE', path, auth: auth);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    String auth = 'none',
    Map<String, String>? query,
  }) async {
    final headers = <String, String>{};
    if (body != null) {
      headers['content-type'] = 'application/json; charset=utf-8';
    }
    final token = switch (auth) {
      'admin' => session.adminToken,
      'staff' => session.kassaToken ?? session.adminToken,
      _ => null,
    };
    if (auth != 'none') {
      if (token == null || token.isEmpty) {
        throw ApiException('PIN kiriting', statusCode: 401);
      }
      headers['authorization'] = 'Bearer $token';
    }

    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    try {
      final response = await _dispatch(method, uri, headers, body).timeout(const Duration(seconds: 25));
      return _decode(response);
    } on TimeoutException {
      throw ApiException('Server javob bermadi');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Serverga ulanib bo\'lmadi. $baseUrl ishlayotganini tekshiring.');
    }
  }

  Future<http.Response> _dispatch(
    String method,
    Uri uri,
    Map<String, String> headers,
    Object? body,
  ) {
    final encoded = body == null ? null : jsonEncode(body);
    switch (method) {
      case 'GET':
        return http.get(uri, headers: headers);
      case 'POST':
        return http.post(uri, headers: headers, body: encoded);
      case 'PUT':
        return http.put(uri, headers: headers, body: encoded);
      case 'PATCH':
        return http.patch(uri, headers: headers, body: encoded);
      case 'DELETE':
        return http.delete(uri, headers: headers);
      default:
        throw ApiException('Noto\'g\'ri so\'rov');
    }
  }

  dynamic _decode(http.Response response) {
    final dynamic decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) return decoded;
    final message = decoded is Map && decoded['error'] is String
        ? decoded['error'] as String
        : 'So\'rov bajarilmadi (${response.statusCode})';
    throw ApiException(message, statusCode: response.statusCode);
  }
}
