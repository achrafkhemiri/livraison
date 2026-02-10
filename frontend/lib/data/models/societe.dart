class Societe {
  final int? id;
  final String raisonSociale;
  final String? siret;
  final String? adresse;
  final String? ville;
  final String? codePostal;
  final String? telephone;
  final String? email;
  final bool actif;

  Societe({
    this.id,
    required this.raisonSociale,
    this.siret,
    this.adresse,
    this.ville,
    this.codePostal,
    this.telephone,
    this.email,
    this.actif = true,
  });

  factory Societe.fromJson(Map<String, dynamic> json) {
    return Societe(
      id: json['id'],
      raisonSociale: json['raisonSociale'] ?? '',
      siret: json['siret'],
      adresse: json['adresse'],
      ville: json['ville'],
      codePostal: json['codePostal'],
      telephone: json['telephone'],
      email: json['email'],
      actif: json['actif'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'raisonSociale': raisonSociale,
      'siret': siret,
      'adresse': adresse,
      'ville': ville,
      'codePostal': codePostal,
      'telephone': telephone,
      'email': email,
      'actif': actif,
    };
  }

  Societe copyWith({
    int? id,
    String? raisonSociale,
    String? siret,
    String? adresse,
    String? ville,
    String? codePostal,
    String? telephone,
    String? email,
    bool? actif,
  }) {
    return Societe(
      id: id ?? this.id,
      raisonSociale: raisonSociale ?? this.raisonSociale,
      siret: siret ?? this.siret,
      adresse: adresse ?? this.adresse,
      ville: ville ?? this.ville,
      codePostal: codePostal ?? this.codePostal,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      actif: actif ?? this.actif,
    );
  }
}
