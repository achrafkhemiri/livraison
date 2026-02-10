class User {
  final int id;
  final String email;
  final String nom;
  final String prenom;
  final String role;
  final String? telephone;
  final int? societeId;
  final String? societeNom;
  final double? latitude;
  final double? longitude;
  final DateTime? dernierePositionAt;
  final bool actif;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.role,
    this.telephone,
    this.societeId,
    this.societeNom,
    this.latitude,
    this.longitude,
    this.dernierePositionAt,
    this.actif = true,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      role: json['role'] ?? '',
      telephone: json['telephone'],
      societeId: json['societeId'],
      societeNom: json['societeNom'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      dernierePositionAt: json['dernierePositionAt'] != null ? DateTime.parse(json['dernierePositionAt']) : null,
      actif: json['actif'] ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'role': role,
      'telephone': telephone,
      'societeId': societeId,
      'latitude': latitude,
      'longitude': longitude,
      'actif': actif,
    };
  }

  bool get isGerant => role == 'GERANT';
  bool get isLivreur => role == 'LIVREUR';
  
  String get fullName => '$prenom $nom';
}
