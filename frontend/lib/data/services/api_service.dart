import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/api_constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }

  Map<String, String> get _baseHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await getToken();
    return {
      ..._baseHeaders,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: await _getAuthHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Erreur de connexion: $e');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: await _getAuthHeaders(),
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Erreur de connexion: $e');
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: await _getAuthHeaders(),
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Erreur de connexion: $e');
    }
  }

  Future<dynamic> patch(String endpoint, {Map<String, dynamic>? data}) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: await _getAuthHeaders(),
        body: data != null ? jsonEncode(data) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Erreur de connexion: $e');
    }
  }

  Future<void> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: await _getAuthHeaders(),
      );
      _handleResponse(response);
    } catch (e) {
      throw ApiException('Erreur de connexion: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw ApiException('Non autorisé', statusCode: 401);
    } else if (response.statusCode == 403) {
      throw ApiException('Accès refusé', statusCode: 403);
    } else if (response.statusCode == 404) {
      throw ApiException('Ressource non trouvée', statusCode: 404);
    } else if (response.statusCode == 409) {
      final body = jsonDecode(response.body);
      throw ApiException(body['message'] ?? 'Conflit', statusCode: 409);
    } else {
      try {
        final body = jsonDecode(response.body);
        throw ApiException(body['message'] ?? 'Erreur serveur', statusCode: response.statusCode);
      } catch (_) {
        throw ApiException('Erreur serveur', statusCode: response.statusCode);
      }
    }
  }
}
