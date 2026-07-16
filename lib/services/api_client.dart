import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../data/api_config.dart';

class ApiClient {
  static const String _tokenKey = 'api_token';

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String? _token;

  String? get token => _token;

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<http.Response> get(Uri uri) => _request('GET', uri);
  Future<http.Response> post(Uri uri, {Object? body}) =>
      _request('POST', uri, body: body);
  Future<http.Response> patch(Uri uri, {Object? body}) =>
      _request('PATCH', uri, body: body);
  Future<http.Response> delete(Uri uri, {Object? body}) =>
      _request('DELETE', uri, body: body);

  Future<http.Response> _request(
    String method,
    Uri uri, {
    Object? body,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }

    final encodedBody = body == null ? null : jsonEncode(body);

    late http.Response response;
    switch (method) {
      case 'GET':
        response = await http.get(uri, headers: headers);
        break;
      case 'POST':
        response = await http.post(uri, headers: headers, body: encodedBody);
        break;
      case 'PATCH':
        response = await http.patch(uri, headers: headers, body: encodedBody);
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: headers, body: encodedBody);
        break;
      default:
        throw UnsupportedError('Método HTTP não suportado: $method');
    }

    if (response.statusCode >= 400) {
      throw ApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    return response;
  }

  Uri buildUri(String path, {Map<String, String>? queryParams}) {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    if (queryParams == null || queryParams.isEmpty) return uri;
    return uri.replace(queryParameters: queryParams);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;

  ApiException({required this.statusCode, required this.body});

  String? get message {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      return decoded['error'] as String?;
    } catch (_) {
      return body.isEmpty ? null : body;
    }
  }

  @override
  String toString() {
    final msg = message;
    if (msg != null && msg.isNotEmpty) {
      return 'Erro $statusCode: $msg';
    }
    return 'Erro $statusCode';
  }
}
