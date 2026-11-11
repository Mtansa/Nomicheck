import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

class ApiClient {
  static String get baseUrl => ApiConfig.baseUrl;

  String? _token;

  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);

    late http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: _headers);
        case 'POST':
          response = await http.post(
            uri,
            headers: _headers,
            body: jsonEncode(body ?? {}),
          );
        case 'PUT':
          response = await http.put(
            uri,
            headers: _headers,
            body: jsonEncode(body ?? {}),
          );
        case 'DELETE':
          response = await http.delete(uri, headers: _headers);
        default:
          throw ApiException(400, 'Método no soportado: $method');
      }
    } catch (e) {
      throw ApiException(0, 'No se pudo conectar con el servidor. Verifica tu conexión.');
    }

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final message = decoded is Map<String, dynamic> && decoded['error'] != null
        ? decoded['error'].toString()
        : 'Error ${response.statusCode}';
    throw ApiException(response.statusCode, message);
  }

  Future<dynamic> get(String path, {Map<String, String>? queryParams}) =>
      _send('GET', path, queryParams: queryParams);

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) =>
      _send('POST', path, body: body);

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) =>
      _send('PUT', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);
}
