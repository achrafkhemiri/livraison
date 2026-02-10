/// Client class - représente un consommateur de l'app (table 'users')
class Client {
  final int? id;
  final String? nom;      // maps to 'name' from backend
  final String? prenom;   // not in users table, but kept for compatibility
  final String? email;
  final String? telephone; // maps to 'phone' from backend
  final String? adresse;  // maps to 'address' from backend
  final String? ville;
  final String? codePostal;
  final double? latitude;
  final double? longitude;
  final String? profileImage;
  final bool actif;

  Client({
    this.id,
    this.nom,
    this.prenom,
    this.email,
    this.telephone,
    this.adresse,
    this.ville,
    this.codePostal,
    this.latitude,
    this.longitude,
    this.profileImage,
    this.actif = true,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      // Backend uses 'name', fallback to 'nom' for compatibility
      nom: json['name'] ?? json['nom'] ?? '',
      prenom: json['prenom'],
      email: json['email'],
      // Backend uses 'phone', fallback to 'telephone'
      telephone: json['phone'] ?? json['telephone'],
      // Backend uses 'address', fallback to 'adresse'
      adresse: json['address'] ?? json['adresse'],
      ville: json['ville'],
      codePostal: json['codePostal'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      profileImage: json['profileImage'],
      actif: json['actif'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': nom,
      'email': email,
      'phone': telephone,
      'address': adresse,
      'latitude': latitude,
      'longitude': longitude,
      'profileImage': profileImage,
    };
  }

  String get fullName => prenom != null && prenom!.isNotEmpty ? '$prenom $nom' : nom ?? 'Client';
}
