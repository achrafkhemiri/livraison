import { Component, OnInit } from '@angular/core';
import { AuthService } from '../../services/auth.service';
import { OrderService } from '../../services/order.service';
import { UtilisateurService } from '../../services/utilisateur.service';
import { Order } from '../../models/order.model';

@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.css']
})
export class DashboardComponent implements OnInit {
  userName = '';
  societeName = '';
  totalOrders = 0;
  pendingOrders = 0;
  deliveredOrders = 0;
  livreurCount = 0;
  recentOrders: Order[] = [];
  loading = true;

  constructor(
    private authService: AuthService,
    private orderService: OrderService,
    private utilisateurService: UtilisateurService
  ) {}

  ngOnInit(): void {
    const user = this.authService.getCurrentUser();
    if (user) {
      this.userName = `${user.prenom} ${user.nom}`;
      this.societeName = user.societeNom || '';
    }

    this.loadData();
  }

  loadData(): void {
    this.loading = true;

    this.orderService.getAll().subscribe({
      next: (orders) => {
        this.totalOrders = orders.length;
        this.pendingOrders = orders.filter(o => o.status === 'pending').length;
        this.deliveredOrders = orders.filter(o => o.status === 'delivered').length;
        this.recentOrders = orders
          .sort((a, b) => {
            const da = a.dateCommande ? new Date(a.dateCommande).getTime() : 0;
            const db = b.dateCommande ? new Date(b.dateCommande).getTime() : 0;
            return db - da;
          })
          .slice(0, 5);
        this.loading = false;
      },
      error: () => { this.loading = false; }
    });

    this.utilisateurService.getLivreurs().subscribe({
      next: (livreurs) => { this.livreurCount = livreurs.length; }
    });
  }

  getStatusLabel(status: string): string {
    const labels: { [key: string]: string } = {
      'pending': 'En attente',
      'assigned': 'Assignée',
      'en_cours': 'En cours',
      'processing': 'En traitement',
      'shipped': 'Expédiée',
      'delivered': 'Livrée',
      'cancelled': 'Annulée'
    };
    return labels[status] || status;
  }

  getStatusClass(status: string): string {
    const classes: { [key: string]: string } = {
      'pending': 'status-pending',
      'assigned': 'status-assigned',
      'en_cours': 'status-en-cours',
      'processing': 'status-processing',
      'shipped': 'status-shipped',
      'delivered': 'status-delivered',
      'cancelled': 'status-cancelled'
    };
    return classes[status] || '';
  }
}
