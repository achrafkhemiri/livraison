class AuthResponse {
  final String token;
  final String type;
  final int id;
  final String email;
  final String nom;
  final String prenom;
  final String role;
  final int? societeId;
  final String? societeNom;

  AuthResponse({
    required this.token,
    required this.type,
    required this.id,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.role,
    this.societeId,
    this.societeNom,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      type: json['type'] ?? 'Bearer',
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      role: json['role'] ?? '',
      societeId: json['societeId'],
      societeNom: json['societeNom'],
    );
  }

  bool get isGerant => role == 'GERANT';
  bool get isLivreur => role == 'LIVREUR';
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class RegisterRequest {
  final String nom;
  final String prenom;
  final String email;
  final String password;
  final String role;
  final String? telephone;

  RegisterRequest({
    required this.nom,
    required this.prenom,
    required this.email,
    required this.password,
    required this.role,
    this.telephone,
  });

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'password': password,
      'role': role,
      'telephone': telephone,
    };
  }
}
