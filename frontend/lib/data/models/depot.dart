import 'stock.dart';

class Depot {
  final int? id;
  final String libelleDepot;
  final String? code;
  final String? nom;
  final String? adresse;
  final String? ville;
  final String? codePostal;
  final String? telephone;
  final int? magasinId;
  final String? magasinNom;
  final double? latitude;
  final double? longitude;
  final int? capaciteStockage;
  final bool? actif;
  final List<Stock>? stocks;

  Depot({
    this.id,
    required this.libelleDepot,
    this.code,
    this.nom,
    this.adresse,
    this.ville,
    this.codePostal,
    this.telephone,
    this.magasinId,
    this.magasinNom,
    this.latitude,
    this.longitude,
    this.capaciteStockage,
    this.actif = true,
    this.stocks,
  });

  factory Depot.fromJson(Map<String, dynamic> json) {
    return Depot(
      id: json['id'],
      libelleDepot: json['libelleDepot'] ?? '',
      code: json['code'],
      nom: json['nom'],
      adresse: json['adresse'],
      ville: json['ville'],
      codePostal: json['codePostal'],
      telephone: json['telephone'],
      magasinId: json['magasinId'],
      magasinNom: json['magasinNom'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      capaciteStockage: json['capaciteStockage'],
      actif: json['actif'],
      stocks: json['stocks'] != null
          ? (json['stocks'] as List).map((e) => Stock.fromJson(e)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'libelleDepot': libelleDepot,
      'code': code,
      'nom': nom,
      'adresse': adresse,
      'ville': ville,
      'codePostal': codePostal,
      'telephone': telephone,
      'magasinId': magasinId,
      'latitude': latitude,
      'longitude': longitude,
      'capaciteStockage': capaciteStockage,
      'actif': actif,
    };
  }
}
