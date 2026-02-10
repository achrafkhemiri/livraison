import 'package:flutter/foundation.dart';
import '../data/models/models.dart';
import '../data/services/services.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _token;
  String? _errorMessage;
  
  AuthStatus get status => _status;
  User? get user => _user;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  
  // Check if user is Gérant (admin)
  bool get isGerant => _user?.role?.toLowerCase() == 'gerant' || 
                        _user?.role?.toLowerCase() == 'admin' ||
                        _user?.role?.toLowerCase() == 'gérant';
  
  // Check if user is Livreur
  bool get isLivreur => _user?.role?.toLowerCase() == 'livreur';
  
  // Initialize auth state
  Future<void> initialize() async {
    _status = AuthStatus.loading;
    notifyListeners();
    
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        _token = await _authService.getToken();
        // TODO: Fetch user profile from backend
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }
  
  // Login
  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _authService.login(email, password);
      
      _token = response.token;
      _user = User(
        id: response.id,
        email: response.email,
        nom: response.nom,
        prenom: response.prenom,
        role: response.role,
        societeId: response.societeId,
        societeNom: response.societeNom,
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // Register
  Future<bool> register({
    required String nom,
    required String prenom,
    required String password,
    required String email,
    required String role,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _authService.register(
        RegisterRequest(
          nom: nom,
          prenom: prenom,
          password: password,
          email: email,
          role: role,
        ),
      );
      
      _token = response.token;
      _user = User(
        id: response.id,
        email: response.email,
        nom: response.nom,
        prenom: response.prenom,
        role: response.role,
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // Logout
  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();
    
    try {
      await _authService.logout();
    } finally {
      _user = null;
      _token = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }
  
  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Update user info locally
  void updateUser(User updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }
}
