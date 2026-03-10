import { Component, OnInit } from '@angular/core';
import { SocieteService } from '../../services/societe.service';
import { Societe } from '../../models/societe.model';

@Component({
  selector: 'app-societes',
  templateUrl: './societes.component.html',
  styleUrls: ['./societes.component.css']
})
export class SocietesComponent implements OnInit {
  societes: Societe[] = [];
  loading = true;
  showForm = false;
  editingSociete: Societe | null = null;
  formData: Societe = this.emptyForm();

  constructor(private societeService: SocieteService) {}

  ngOnInit(): void {
    this.loadData();
  }

  emptyForm(): Societe {
    return {
      raisonSociale: '',
      siret: '',
      adresse: '',
      ville: '',
      codePostal: '',
      telephone: '',
      email: '',
      actif: true,
      fraisLivraison: undefined,
      latitude: undefined,
      longitude: undefined
    };
  }

  loadData(): void {
    this.loading = true;
    this.societeService.getAll().subscribe({
      next: (data) => { this.societes = data; this.loading = false; },
      error: () => { this.loading = false; }
    });
  }

  openCreate(): void {
    this.editingSociete = null;
    this.formData = this.emptyForm();
    this.showForm = true;
  }

  openEdit(societe: Societe): void {
    this.editingSociete = societe;
    this.formData = { ...societe };
    this.showForm = true;
  }

  closeForm(): void {
    this.showForm = false;
    this.editingSociete = null;
  }

  save(): void {
    if (!this.formData.raisonSociale) return;
    if (this.editingSociete && this.editingSociete.id) {
      this.societeService.update(this.editingSociete.id, this.formData).subscribe({
        next: () => { this.closeForm(); this.loadData(); }
      });
    } else {
      this.societeService.create(this.formData).subscribe({
        next: () => { this.closeForm(); this.loadData(); }
      });
    }
  }

  delete(societe: Societe): void {
    if (!societe.id) return;
    if (confirm(`Supprimer la société "${societe.raisonSociale}" ?`)) {
      this.societeService.delete(societe.id).subscribe({
        next: () => this.loadData()
      });
    }
  }
}
