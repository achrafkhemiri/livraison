import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { MagasinService } from '../../services/magasin.service';
import { SocieteService } from '../../services/societe.service';
import { Magasin } from '../../models/magasin.model';
import { Societe } from '../../models/societe.model';

@Component({
  selector: 'app-magasins',
  templateUrl: './magasins.component.html',
  styleUrls: ['./magasins.component.css']
})
export class MagasinsComponent implements OnInit {
  magasins: Magasin[] = [];
  societes: Societe[] = [];
  loading = true;
  showForm = false;
  editingMagasin: Magasin | null = null;
  formData: Magasin = this.emptyForm();
  filterSocieteId: number | null = null;

  constructor(
    private magasinService: MagasinService,
    private societeService: SocieteService,
    private route: ActivatedRoute
  ) {}

  ngOnInit(): void {
    this.route.queryParams.subscribe(params => {
      this.filterSocieteId = params['societeId'] ? +params['societeId'] : null;
      this.loadData();
    });
    this.societeService.getAll().subscribe(s => this.societes = s);
  }

  emptyForm(): Magasin {
    return { code: '', nom: '', adresse: '', ville: '', codePostal: '', telephone: '', email: '', actif: true, societeId: undefined, latitude: undefined, longitude: undefined };
  }

  loadData(): void {
    this.loading = true;
    const obs = this.filterSocieteId
      ? this.magasinService.getBySocieteId(this.filterSocieteId)
      : this.magasinService.getAll();
    obs.subscribe({
      next: (data) => { this.magasins = data; this.loading = false; },
      error: () => { this.loading = false; }
    });
  }

  openCreate(): void {
    this.editingMagasin = null;
    this.formData = this.emptyForm();
    if (this.filterSocieteId) this.formData.societeId = this.filterSocieteId;
    this.showForm = true;
  }

  openEdit(m: Magasin): void {
    this.editingMagasin = m;
    this.formData = { ...m };
    this.showForm = true;
  }

  closeForm(): void { this.showForm = false; this.editingMagasin = null; }

  save(): void {
    if (!this.formData.nom) return;
    if (this.editingMagasin && this.editingMagasin.id) {
      this.magasinService.update(this.editingMagasin.id, this.formData).subscribe({
        next: () => { this.closeForm(); this.loadData(); }
      });
    } else {
      this.magasinService.create(this.formData).subscribe({
        next: () => { this.closeForm(); this.loadData(); }
      });
    }
  }

  delete(m: Magasin): void {
    if (!m.id) return;
    if (confirm(`Supprimer le magasin "${m.nom}" ?`)) {
      this.magasinService.delete(m.id).subscribe({ next: () => this.loadData() });
    }
  }
}
