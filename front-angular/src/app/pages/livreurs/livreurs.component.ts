import { Component, OnInit } from '@angular/core';
import { UtilisateurService } from '../../services/utilisateur.service';
import { CommissionService } from '../../services/commission.service';
import { CommissionConfig } from '../../models/commission.model';
import { User, CreateUtilisateur } from '../../models/user.model';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-livreurs',
  templateUrl: './livreurs.component.html',
  styleUrls: ['./livreurs.component.css']
})
export class LivreursComponent implements OnInit {
  livreurs: User[] = [];
  loading = true;
  showForm = false;
  editingLivreur: User | null = null;
  formData: CreateUtilisateur = this.emptyForm();

  // Commission config fields for the livreur form
  commissionMontantFixe: number = 0;
  commissionPrixParKm: number = 0;
  commissionBonus: number = 0;
  commissionInclureCollection: boolean = false;
  livreurActiveConfig: CommissionConfig | null = null;
  // Map livreurId -> active config for display in cards
  livreurConfigs: { [id: number]: CommissionConfig } = {};

  constructor(
    private utilisateurService: UtilisateurService,
    private commissionService: CommissionService,
    private authService: AuthService
  ) {}

  ngOnInit(): void { this.loadData(); }

  emptyForm(): CreateUtilisateur {
    return { nom: '', prenom: '', email: '', password: '', role: 'LIVREUR', telephone: '', societeId: this.authService.getCurrentUser()?.societeId };
  }

  resetCommissionFields(): void {
    this.commissionMontantFixe = 0;
    this.commissionPrixParKm = 0;
    this.commissionBonus = 0;
    this.commissionInclureCollection = false;
    this.livreurActiveConfig = null;
  }

  loadData(): void {
    this.loading = true;
    this.utilisateurService.getLivreurs().subscribe({
      next: (data) => {
        this.livreurs = data;
        this.loading = false;
        // Load commission configs for all livreurs
        this.livreurs.forEach(l => {
          this.commissionService.getActiveConfigByLivreur(l.id).subscribe({
            next: (config) => { if (config) this.livreurConfigs[l.id] = config; },
            error: () => {} // 204 No Content or error — no config
          });
        });
      },
      error: () => { this.loading = false; }
    });
  }

  openCreate(): void {
    this.editingLivreur = null;
    this.formData = this.emptyForm();
    this.resetCommissionFields();
    this.showForm = true;
  }

  openEdit(l: User): void {
    this.editingLivreur = l;
    this.formData = { nom: l.nom, prenom: l.prenom, email: l.email, password: '', role: 'LIVREUR', telephone: l.telephone, societeId: l.societeId };

    // Load existing commission config for this livreur
    this.resetCommissionFields();
    this.commissionService.getActiveConfigByLivreur(l.id).subscribe({
      next: (config) => {
        if (config) {
          this.livreurActiveConfig = config;
          this.commissionMontantFixe = config.montantFixe || 0;
          this.commissionPrixParKm = config.prixParKm || 0;
          this.commissionBonus = config.bonus || 0;
          this.commissionInclureCollection = config.inclureDistanceCollection || false;
        }
      },
      error: () => {} // no config
    });
    this.showForm = true;
  }

  closeForm(): void { this.showForm = false; this.editingLivreur = null; }

  save(): void {
    if (!this.formData.nom || !this.formData.prenom || !this.formData.email) return;
    if (this.editingLivreur) {
      const updateData: User = {
        id: this.editingLivreur.id,
        nom: this.formData.nom,
        prenom: this.formData.prenom,
        email: this.formData.email,
        role: 'LIVREUR',
        telephone: this.formData.telephone,
        societeId: this.formData.societeId,
        actif: true
      };
      this.utilisateurService.update(this.editingLivreur.id, updateData).subscribe({
        next: () => {
          this.saveCommissionConfig(this.editingLivreur!.id);
          this.closeForm();
          this.loadData();
        }
      });
    } else {
      if (!this.formData.password) return;
      this.utilisateurService.create(this.formData).subscribe({
        next: (created) => {
          this.saveCommissionConfig(created.id);
          this.closeForm();
          this.loadData();
        }
      });
    }
  }

  saveCommissionConfig(livreurId: number): void {
    const payload: CommissionConfig = {
      livreurId: livreurId,
      montantFixe: this.commissionMontantFixe || 0,
      prixParKm: this.commissionPrixParKm || 0,
      bonus: this.commissionBonus || 0,
      inclureDistanceCollection: this.commissionInclureCollection
    };

    if (this.livreurActiveConfig && this.livreurActiveConfig.id) {
      // Update existing config
      this.commissionService.updateConfig(this.livreurActiveConfig.id, payload).subscribe();
    } else {
      // Create new config
      this.commissionService.createConfig(payload).subscribe();
    }
  }

  delete(l: User): void {
    if (confirm(`Supprimer le livreur "${l.prenom} ${l.nom}" ?`)) {
      this.utilisateurService.delete(l.id).subscribe({ next: () => this.loadData() });
    }
  }

  hasPosition(l: User): boolean {
    return !!(l.latitude && l.longitude);
  }

  hasConfig(l: User): boolean {
    return !!this.livreurConfigs[l.id];
  }

  getConfigSummary(l: User): string {
    const c = this.livreurConfigs[l.id];
    if (!c) return 'Pas de commission';
    return `Fixe: ${c.montantFixe} | /km: ${c.prixParKm} | Bonus: ${c.bonus}`;
  }
}
