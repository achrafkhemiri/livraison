import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';
import '../../core/constants/api_constants.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _userDataKey = 'user_data';

  Future<AuthResponse> login(String email, String password) async {
    final response = await _api.post(
      ApiConstants.login,
      LoginRequest(email: email, password: password).toJson(),
    );
    
    final authResponse = AuthResponse.fromJson(response);
    await _api.saveToken(authResponse.token);
    return authResponse;
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    final response = await _api.post(
      ApiConstants.register,
      request.toJson(),
    );
    
    final authResponse = AuthResponse.fromJson(response);
    await _api.saveToken(authResponse.token);
    return authResponse;
  }

  Future<void> logout() async {
    await _api.deleteToken();
    await _storage.delete(key: _userDataKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await _api.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> getToken() async {
    return await _api.getToken();
  }

  // Save user data to secure storage
  Future<void> saveUserData(User user) async {
    await _storage.write(key: _userDataKey, value: jsonEncode(user.toJson()));
  }

  // Load user data from secure storage
  Future<User?> loadUserData() async {
    final data = await _storage.read(key: _userDataKey);
    if (data != null && data.isNotEmpty) {
      return User.fromJson(jsonDecode(data));
    }
    return null;
  }

  // Fetch current user profile from backend (/auth/me)
  Future<User> fetchMe() async {
    final response = await _api.get(ApiConstants.me);
    return User.fromJson(response);
  }
}
