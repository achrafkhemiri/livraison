class Produit {
  final int? id;
  final String reference;
  final String designation;
  final String? description;
  final double prixHT;
  final double prixTTC;
  final int? tvaId;
  final double? tauxTva;
  final String? categorie;
  final String? unite;
  final double? poids;
  final bool actif;

  Produit({
    this.id,
    required this.reference,
    required this.designation,
    this.description,
    required this.prixHT,
    required this.prixTTC,
    this.tvaId,
    this.tauxTva,
    this.categorie,
    this.unite,
    this.poids,
    this.actif = true,
  });

  factory Produit.fromJson(Map<String, dynamic> json) {
    return Produit(
      id: json['id'],
      reference: json['reference'] ?? '',
      designation: json['designation'] ?? '',
      description: json['description'],
      prixHT: (json['prixHT'] ?? 0).toDouble(),
      prixTTC: (json['prixTTC'] ?? 0).toDouble(),
      tvaId: json['tvaId'],
      tauxTva: json['tauxTva']?.toDouble(),
      categorie: json['categorie'],
      unite: json['unite'],
      poids: json['poids']?.toDouble(),
      actif: json['actif'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'reference': reference,
      'designation': designation,
      'description': description,
      'prixHT': prixHT,
      'prixTTC': prixTTC,
      'tvaId': tvaId,
      'categorie': categorie,
      'unite': unite,
      'poids': poids,
      'actif': actif,
    };
  }
}
