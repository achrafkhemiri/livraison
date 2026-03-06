import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-login',
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css']
})
export class LoginComponent {
  email = '';
  password = '';
  loading = false;
  errorMessage = '';

  constructor(private authService: AuthService, private router: Router) {
    if (this.authService.isLoggedIn() && this.authService.isGerant()) {
      this.router.navigate(['/dashboard']);
    }
  }

  onLogin(): void {
    if (!this.email || !this.password) {
      this.errorMessage = 'Veuillez remplir tous les champs';
      return;
    }

    this.loading = true;
    this.errorMessage = '';

    this.authService.login({ email: this.email, password: this.password }).subscribe({
      next: (response) => {
        this.loading = false;
        const role = response.role.toLowerCase();
        if (role === 'gerant' || role === 'admin' || role === 'gérant') {
          this.router.navigate(['/dashboard']);
        } else {
          this.errorMessage = 'Accès réservé aux administrateurs';
          this.authService.logout();
        }
      },
      error: (err) => {
        this.loading = false;
        this.errorMessage = err.status === 401
          ? 'Email ou mot de passe incorrect'
          : 'Erreur de connexion au serveur';
      }
    });
  }
}
