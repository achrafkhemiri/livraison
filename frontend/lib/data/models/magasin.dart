class Magasin {
  final int? id;
  final String code;
  final String nom;
  final String? adresse;
  final String? ville;
  final String? codePostal;
  final String? telephone;
  final String? email;
  final double? latitude;
  final double? longitude;
  final int? societeId;
  final String? societeNom;
  final bool actif;

  Magasin({
    this.id,
    required this.code,
    required this.nom,
    this.adresse,
    this.ville,
    this.codePostal,
    this.telephone,
    this.email,
    this.latitude,
    this.longitude,
    this.societeId,
    this.societeNom,
    this.actif = true,
  });

  factory Magasin.fromJson(Map<String, dynamic> json) {
    return Magasin(
      id: json['id'],
      code: json['code'] ?? '',
      nom: json['nom'] ?? '',
      adresse: json['adresse'],
      ville: json['ville'],
      codePostal: json['codePostal'],
      telephone: json['telephone'],
      email: json['email'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      societeId: json['societeId'],
      societeNom: json['societeNom'],
      actif: json['actif'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'code': code,
      'nom': nom,
      'adresse': adresse,
      'ville': ville,
      'codePostal': codePostal,
      'telephone': telephone,
      'email': email,
      'latitude': latitude,
      'longitude': longitude,
      'societeId': societeId,
      'actif': actif,
    };
  }

  Magasin copyWith({
    int? id,
    String? code,
    String? nom,
    String? adresse,
    String? ville,
    String? codePostal,
    String? telephone,
    String? email,
    double? latitude,
    double? longitude,
    int? societeId,
    String? societeNom,
    bool? actif,
  }) {
    return Magasin(
      id: id ?? this.id,
      code: code ?? this.code,
      nom: nom ?? this.nom,
      adresse: adresse ?? this.adresse,
      ville: ville ?? this.ville,
      codePostal: codePostal ?? this.codePostal,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      societeId: societeId ?? this.societeId,
      societeNom: societeNom ?? this.societeNom,
      actif: actif ?? this.actif,
    );
  }
}
