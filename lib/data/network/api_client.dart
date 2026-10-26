import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'api_constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (Status: ${statusCode ?? 'N/A'})';
}

class ApiClient {
  final http.Client _client;
  final FirebaseAuth _auth;

  ApiClient({http.Client? client, FirebaseAuth? auth})
      : _client = client ?? http.Client(),
        _auth = auth ?? FirebaseAuth.instance;

  /// Retrieves a fresh Firebase ID token.
  Future<String?> _getFreshToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    // Always force refresh token to prevent expired token issues
    return await user.getIdToken(true);
  }

  /// Helper to build authorized headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getFreshToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Perform GET request
  Future<dynamic> get(String endpoint) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders();

    try {
      final response = await _client.get(uri, headers: headers);
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error de red al conectar con el servidor: $e');
    }
  }

  /// Perform POST request
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders();

    try {
      final response = await _client.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error de red al conectar con el servidor: $e');
    }
  }

  /// Perform PUT request
  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders();

    try {
      final response = await _client.put(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error de red al conectar con el servidor: $e');
    }
  }

  /// Process HTTP response and return JSON or handle errors
  dynamic _processResponse(http.Response response) {
    dynamic responseJson;
    try {
      if (response.body.isNotEmpty) {
        responseJson = jsonDecode(response.body);
      }
    } catch (_) {
      responseJson = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseJson;
    } else if (response.statusCode == 404) {
      throw ApiException('Recurso no encontrado (404)', statusCode: 404);
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw ApiException('No autorizado. Sesión inválida o expirada.', statusCode: response.statusCode);
    } else {
      final errorMessage = responseJson is Map && responseJson.containsKey('message')
          ? responseJson['message']
          : 'Error en la solicitud al servidor';
      throw ApiException(errorMessage.toString(), statusCode: response.statusCode);
    }
  }
}
