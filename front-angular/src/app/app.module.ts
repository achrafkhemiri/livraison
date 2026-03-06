import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { HttpClientModule, HTTP_INTERCEPTORS } from '@angular/common/http';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';

// Interceptors & Guards
import { AuthInterceptor } from './interceptors/auth.interceptor';

// Layout
import { LayoutComponent } from './layout/layout.component';

// Pages
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

@NgModule({
  declarations: [
    AppComponent,
    LayoutComponent,
    LoginComponent,
    DashboardComponent,
    SocietesComponent,
    MagasinsComponent,
    DepotsComponent,
    ProduitsComponent,
    LivreursComponent,
    CommandesComponent,
    CarteComponent,
    ProfileComponent,
    CommissionsComponent
  ],
  imports: [
    BrowserModule,
    BrowserAnimationsModule,
    HttpClientModule,
    FormsModule,
    ReactiveFormsModule,
    AppRoutingModule
  ],
  providers: [
    { provide: HTTP_INTERCEPTORS, useClass: AuthInterceptor, multi: true }
  ],
  bootstrap: [AppComponent]
})
export class AppModule { }
