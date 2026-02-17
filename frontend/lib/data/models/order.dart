class Order {
  final int? id;
  final String? numero;
  final int? userId;
  final int? societeId;
  final String? societeNom;
  final int clientId;
  final String? clientNom;
  final String? clientPhone;
  final String? clientEmail;
  final double? clientLatitude;
  final double? clientLongitude;
  final int? livreurId;
  final String? livreurNom;
  final int? depotId;
  final String? depotNom;
  final String status;
  final double? montantHT;
  final double? montantTVA;
  final double? montantTTC;
  final String? adresseLivraison;
  final double? latitudeLivraison;
  final double? longitudeLivraison;
  final DateTime? dateCommande;
  final DateTime? dateLivraisonPrevue;
  final DateTime? dateLivraisonEffective;
  final String? notes;
  final List<OrderItem>? items;
  final bool? collected;
  final String? collectionPlan;
  final DateTime? dateCollection;

  Order({
    this.id,
    this.numero,
    this.userId,
    this.societeId,
    this.societeNom,
    required this.clientId,
    this.clientNom,
    this.clientPhone,
    this.clientEmail,
    this.clientLatitude,
    this.clientLongitude,
    this.livreurId,
    this.livreurNom,
    this.depotId,
    this.depotNom,
    this.status = 'pending',
    this.montantHT,
    this.montantTVA,
    this.montantTTC,
    this.adresseLivraison,
    this.latitudeLivraison,
    this.longitudeLivraison,
    this.dateCommande,
    this.dateLivraisonPrevue,
    this.dateLivraisonEffective,
    this.notes,
    this.items,
    this.collected,
    this.collectionPlan,
    this.dateCollection,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      numero: json['numero'],
      userId: json['userId'],
      societeId: json['societeId'],
      societeNom: json['societeNom'],
      clientId: json['clientId'] ?? 0,
      clientNom: json['clientNom'],
      clientPhone: json['clientPhone'],
      clientEmail: json['clientEmail'],
      clientLatitude: json['clientLatitude']?.toDouble(),
      clientLongitude: json['clientLongitude']?.toDouble(),
      livreurId: json['livreurId'],
      livreurNom: json['livreurNom'],
      depotId: json['depotId'],
      depotNom: json['depotNom'],
      status: json['status'] ?? 'pending',
      montantHT: json['montantHT']?.toDouble(),
      montantTVA: json['montantTVA']?.toDouble(),
      montantTTC: json['montantTTC']?.toDouble(),
      adresseLivraison: json['adresseLivraison'],
      latitudeLivraison: json['latitudeLivraison']?.toDouble(),
      longitudeLivraison: json['longitudeLivraison']?.toDouble(),
      dateCommande: json['dateCommande'] != null ? DateTime.parse(json['dateCommande']) : null,
      dateLivraisonPrevue: json['dateLivraisonPrevue'] != null ? DateTime.parse(json['dateLivraisonPrevue']) : null,
      dateLivraisonEffective: json['dateLivraisonEffective'] != null ? DateTime.parse(json['dateLivraisonEffective']) : null,
      notes: json['notes'],
      items: json['items'] != null 
          ? (json['items'] as List).map((e) => OrderItem.fromJson(e)).toList()
          : null,
      collected: json['collected'],
      collectionPlan: json['collectionPlan'],
      dateCollection: json['dateCollection'] != null ? DateTime.parse(json['dateCollection']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'clientId': clientId,
      'livreurId': livreurId,
      'depotId': depotId,
      'status': status,
      'adresseLivraison': adresseLivraison,
      'latitudeLivraison': latitudeLivraison,
      'longitudeLivraison': longitudeLivraison,
      'dateLivraisonPrevue': dateLivraisonPrevue?.toIso8601String(),
      'notes': notes,
      if (collectionPlan != null) 'collectionPlan': collectionPlan,
      if (items != null) 'items': items!.map((e) => e.toJson()).toList(),
    };
  }

  // Status helpers
  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isShipped => status == 'shipped';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';
  
  String get statusLabel {
    switch (status) {
      case 'pending': return 'En attente';
      case 'processing': return 'En traitement';
      case 'shipped': return 'En livraison';
      case 'delivered': return 'Livrée';
      case 'cancelled': return 'Annulée';
      default: return status;
    }
  }

  Order copyWith({
    int? id,
    String? numero,
    int? userId,
    int? clientId,
    String? clientNom,
    String? clientPhone,
    String? clientEmail,
    double? clientLatitude,
    double? clientLongitude,
    int? livreurId,
    String? livreurNom,
    int? depotId,
    String? depotNom,
    int? societeId,
    String? societeNom,
    String? status,
    String? adresseLivraison,
    double? latitudeLivraison,
    double? longitudeLivraison,
    String? notes,
    bool? collected,
    String? collectionPlan,
    DateTime? dateCollection,
  }) {
    return Order(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      userId: userId ?? this.userId,
      clientId: clientId ?? this.clientId,
      clientNom: clientNom ?? this.clientNom,
      clientPhone: clientPhone ?? this.clientPhone,
      clientEmail: clientEmail ?? this.clientEmail,
      clientLatitude: clientLatitude ?? this.clientLatitude,
      clientLongitude: clientLongitude ?? this.clientLongitude,
      livreurId: livreurId ?? this.livreurId,
      livreurNom: livreurNom ?? this.livreurNom,
      depotId: depotId ?? this.depotId,
      depotNom: depotNom ?? this.depotNom,
      societeId: societeId ?? this.societeId,
      societeNom: societeNom ?? this.societeNom,
      status: status ?? this.status,
      montantHT: montantHT,
      montantTVA: montantTVA,
      montantTTC: montantTTC,
      adresseLivraison: adresseLivraison ?? this.adresseLivraison,
      latitudeLivraison: latitudeLivraison ?? this.latitudeLivraison,
      longitudeLivraison: longitudeLivraison ?? this.longitudeLivraison,
      dateCommande: dateCommande,
      dateLivraisonPrevue: dateLivraisonPrevue,
      dateLivraisonEffective: dateLivraisonEffective,
      notes: notes ?? this.notes,
      items: items,
      collected: collected ?? this.collected,
      collectionPlan: collectionPlan ?? this.collectionPlan,
      dateCollection: dateCollection ?? this.dateCollection,
    );
  }
}

class OrderItem {
  final int? id;
  final int? produitId;
  final String? produitCode;
  final String? produitNom;
  final String? produitDesignation;
  final int quantite;
  final double? prixUnitaireHT;
  final double? prixUnitaireTTC;
  final double? remise;
  final double? tauxTva;
  final double? montantHT;
  final double? montantTVA;
  final double? montantTTC;

  OrderItem({
    this.id,
    this.produitId,
    this.produitCode,
    this.produitNom,
    this.produitDesignation,
    required this.quantite,
    this.prixUnitaireHT,
    this.prixUnitaireTTC,
    this.remise,
    this.tauxTva,
    this.montantHT,
    this.montantTVA,
    this.montantTTC,
  });

  // Helper to get product name from any available field
  String get displayName => produitDesignation ?? produitNom ?? produitCode ?? 'Produit #$produitId';

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      produitId: json['produitId'],
      produitCode: json['produitCode'],
      produitNom: json['produitNom'],
      produitDesignation: json['produitDesignation'],
      quantite: json['quantite'] ?? 0,
      prixUnitaireHT: json['prixUnitaireHT']?.toDouble(),
      prixUnitaireTTC: json['prixUnitaireTTC']?.toDouble(),
      remise: json['remise']?.toDouble(),
      tauxTva: json['tauxTva']?.toDouble(),
      montantHT: json['montantHT']?.toDouble(),
      montantTVA: json['montantTVA']?.toDouble(),
      montantTTC: json['montantTTC']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'produitId': produitId,
      'quantite': quantite,
      'remise': remise,
    };
  }
}
