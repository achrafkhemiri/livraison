import { Component, OnInit } from '@angular/core';
import { AuthService } from '../../services/auth.service';
import { SocieteService } from '../../services/societe.service';
import { Router } from '@angular/router';

@Component({
  selector: 'app-profile',
  templateUrl: './profile.component.html',
  styleUrls: ['./profile.component.css']
})
export class ProfileComponent implements OnInit {
  user: any = {};
  societe: any = null;
  loading = true;

  showPasswordForm = false;
  passwordForm = { currentPassword: '', newPassword: '', confirmPassword: '' };
  passwordError = '';
  passwordSuccess = '';

  constructor(
    private authService: AuthService,
    private societeService: SocieteService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadProfile();
  }

  loadProfile(): void {
    this.loading = true;
    const token = this.authService.getToken();
    if (token) {
      try {
        const payload = JSON.parse(atob(token.split('.')[1]));
        this.user = {
          email: payload.sub || payload.email || '',
          nom: payload.nom || '',
          prenom: payload.prenom || '',
          role: payload.role || payload.roles?.[0] || '',
          societeId: payload.societeId || null,
          telephone: payload.telephone || ''
        };
      } catch (e) {
        this.user = { email: 'Utilisateur', role: 'GERANT' };
      }
    }

    if (this.user.societeId) {
      this.societeService.getById(this.user.societeId).subscribe({
        next: (s) => { this.societe = s; this.loading = false; },
        error: () => { this.loading = false; }
      });
    } else {
      // Try loading first société
      this.societeService.getAll().subscribe({
        next: (list) => { this.societe = list?.[0] || null; this.loading = false; },
        error: () => { this.loading = false; }
      });
    }
  }

  getInitials(): string {
    const p = this.user.prenom?.charAt(0) || '';
    const n = this.user.nom?.charAt(0) || '';
    return (p + n).toUpperCase() || this.user.email?.charAt(0)?.toUpperCase() || 'U';
  }

  getRoleLabel(): string {
    const r = (this.user.role || '').toUpperCase();
    if (r.includes('GERANT') || r.includes('ADMIN')) return 'Gérant / Administrateur';
    if (r.includes('LIVREUR')) return 'Livreur';
    return r || 'Utilisateur';
  }

  logout(): void {
    this.authService.logout();
    this.router.navigate(['/login']);
  }
}
