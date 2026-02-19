class AppNotification {
  final int? id;
  final int? destinataireId;
  final String? type;
  final String? message;
  final int? orderId;
  final int? livreurId;
  final bool isRead;
  final DateTime? createdAt;

  AppNotification({
    this.id,
    this.destinataireId,
    this.type,
    this.message,
    this.orderId,
    this.livreurId,
    this.isRead = false,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      destinataireId: json['destinataireId'],
      type: json['type'],
      message: json['message'],
      orderId: json['orderId'],
      livreurId: json['livreurId'],
      isRead: json['isRead'] ?? json['read'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  /// Human-readable label for the notification type
  String get typeLabel {
    switch (type) {
      case 'ORDER_PROPOSED':
        return 'Nouvelle commande proposée';
      case 'ORDER_ACCEPTED':
        return 'Commande acceptée';
      case 'ORDER_REJECTED':
        return 'Commande refusée';
      case 'ORDER_ASSIGNED':
        return 'Commande assignée';
      case 'ORDER_STATUS':
        return 'Statut commande';
      default:
        return 'Notification';
    }
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      destinataireId: destinataireId,
      type: type,
      message: message,
      orderId: orderId,
      livreurId: livreurId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
