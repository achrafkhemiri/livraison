import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { AuthGuard } from './guards/auth.guard';
import { LayoutComponent } from './layout/layout.component';
import { LoginComponent } from './pages/login/login.component';
import { DashboardComponent } from './pages/dashboard/dashboard.component';
import { SocietesComponent } from './pages/societes/societes.component';
import { MagasinsComponent } from './pages/magasins/magasins.component';
import { DepotsComponent } from './pages/depots/depots.component';
import { ProduitsComponent } from './pages/produits/produits.component';
import { LivreursComponent } from './pages/livreurs/livreurs.component';
import { CommandesComponent } from './pages/commandes/commandes.component';
import { CarteComponent } from './pages/carte/carte.component';
import { ProfileComponent } from './pages/profile/profile.component';
import { CommissionsComponent } from './pages/commissions/commissions.component';

const routes: Routes = [
  { path: 'login', component: LoginComponent },
  {
    path: '',
    component: LayoutComponent,
    canActivate: [AuthGuard],
    children: [
      { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
      { path: 'dashboard', component: DashboardComponent },
      { path: 'societes', component: SocietesComponent },
      { path: 'magasins', component: MagasinsComponent },
      { path: 'depots', component: DepotsComponent },
      { path: 'produits', component: ProduitsComponent },
      { path: 'livreurs', component: LivreursComponent },
      { path: 'commandes', component: CommandesComponent },
      { path: 'commissions', component: CommissionsComponent },
      { path: 'carte', component: CarteComponent },
      { path: 'profile', component: ProfileComponent }
    ]
  },
  { path: '**', redirectTo: '' }
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }
