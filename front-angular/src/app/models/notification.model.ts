export interface AppNotification {
  id?: number;
  destinataireId?: number;
  type?: string;
  message?: string;
  orderId?: number;
  livreurId?: number;
  isRead: boolean;
  createdAt?: string;
}
