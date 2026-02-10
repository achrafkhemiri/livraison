class Stock {
  final int? id;
  final int depotId;
  final String? depotNom;
  final int produitId;
  final String? produitCode;
  final String? produitDesignation;
  final double quantiteDisponible;
  final double? quantiteReservee;
  final double? quantiteMinimum;
  final double? quantiteMaximum;

  Stock({
    this.id,
    required this.depotId,
    this.depotNom,
    required this.produitId,
    this.produitCode,
    this.produitDesignation,
    required this.quantiteDisponible,
    this.quantiteReservee,
    this.quantiteMinimum,
    this.quantiteMaximum,
  });

  // Helper to get product name
  String get produitNom => produitDesignation ?? produitCode ?? 'Produit #$produitId';

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      id: json['id'],
      depotId: json['depotId'] ?? 0,
      depotNom: json['depotNom'],
      produitId: json['produitId'] ?? 0,
      produitCode: json['produitCode'],
      produitDesignation: json['produitDesignation'],
      quantiteDisponible: (json['quantiteDisponible'] ?? json['quantite'] ?? 0).toDouble(),
      quantiteReservee: json['quantiteReservee']?.toDouble(),
      quantiteMinimum: json['quantiteMinimum']?.toDouble(),
      quantiteMaximum: json['quantiteMaximum']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'depotId': depotId,
      'produitId': produitId,
      'quantiteDisponible': quantiteDisponible,
      'quantiteMinimum': quantiteMinimum,
      'quantiteMaximum': quantiteMaximum,
    };
  }

  bool get isLowStock => quantiteMinimum != null && quantiteDisponible <= quantiteMinimum!;
  bool get isOutOfStock => quantiteDisponible <= 0;
}
