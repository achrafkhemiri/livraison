import { Component, OnInit, OnDestroy } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from '../services/auth.service';
import { NotificationService } from '../services/notification.service';
import { AppNotification } from '../models/notification.model';
import { Subscription, interval } from 'rxjs';
import { switchMap } from 'rxjs/operators';

@Component({
  selector: 'app-layout',
  templateUrl: './layout.component.html',
  styleUrls: ['./layout.component.css']
})
export class LayoutComponent implements OnInit, OnDestroy {
  sidebarCollapsed = false;
  showNotifications = false;
  showProfileMenu = false;
  unreadCount = 0;
  notifications: AppNotification[] = [];
  userName = '';
  userRole = '';
  societeName = '';
  private pollSub?: Subscription;

  menuItems = [
    { icon: 'dashboard', label: 'Tableau de bord', route: '/dashboard' },
    { icon: 'business', label: 'Sociétés', route: '/societes' },
    { icon: 'store', label: 'Magasins', route: '/magasins' },
    { icon: 'warehouse', label: 'Dépôts', route: '/depots' },
    { icon: 'inventory_2', label: 'Produits', route: '/produits' },
    { icon: 'people', label: 'Livreurs', route: '/livreurs' },
    { icon: 'shopping_cart', label: 'Commandes', route: '/commandes' },
    { icon: 'payments', label: 'Commissions', route: '/commissions' },
    { icon: 'map', label: 'Carte', route: '/carte' },
  ];

  constructor(
    private authService: AuthService,
    private notificationService: NotificationService,
    private router: Router
  ) {}

  ngOnInit(): void {
    const user = this.authService.getCurrentUser();
    if (user) {
      this.userName = `${user.prenom} ${user.nom}`;
      this.userRole = user.role;
      this.societeName = user.societeNom || '';
    }

    this.loadUnreadCount();
    this.pollSub = interval(15000).pipe(
      switchMap(() => this.notificationService.getUnreadCount())
    ).subscribe((res: any) => {
      this.unreadCount = res.count;
    });
  }

  ngOnDestroy(): void {
    this.pollSub?.unsubscribe();
  }

  loadUnreadCount(): void {
    this.notificationService.getUnreadCount().subscribe((res: any) => {
      this.unreadCount = res.count;
    });
  }

  toggleSidebar(): void {
    this.sidebarCollapsed = !this.sidebarCollapsed;
  }

  toggleNotifications(): void {
    this.showNotifications = !this.showNotifications;
    this.showProfileMenu = false;
    if (this.showNotifications) {
      this.notificationService.getAll().subscribe((notifs: AppNotification[]) => {
        this.notifications = notifs;
      });
    }
  }

  toggleProfileMenu(): void {
    this.showProfileMenu = !this.showProfileMenu;
    this.showNotifications = false;
  }

  markAllAsRead(): void {
    this.notificationService.markAllAsRead().subscribe(() => {
      this.notifications.forEach(n => n.isRead = true);
      this.unreadCount = 0;
    });
  }

  getNotificationIcon(type?: string): string {
    switch (type) {
      case 'ORDER_PROPOSED': return 'local_shipping';
      case 'ORDER_ACCEPTED': return 'check_circle';
      case 'ORDER_REJECTED': return 'cancel';
      case 'ORDER_ASSIGNED': return 'assignment_ind';
      case 'ORDER_STATUS': return 'info';
      default: return 'notifications';
    }
  }

  logout(): void {
    this.authService.logout();
    this.router.navigate(['/login']);
  }

  getUserInitials(): string {
    const user = this.authService.getCurrentUser();
    if (!user) return 'A';
    return (user.prenom?.charAt(0) || '') + (user.nom?.charAt(0) || '');
  }

  closeDropdowns(): void {
    this.showNotifications = false;
    this.showProfileMenu = false;
  }
}
