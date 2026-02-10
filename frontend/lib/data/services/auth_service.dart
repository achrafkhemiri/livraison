import '../models/models.dart';
import '../../core/constants/api_constants.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

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
  }

  Future<bool> isLoggedIn() async {
    final token = await _api.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> getToken() async {
    return await _api.getToken();
  }
}
