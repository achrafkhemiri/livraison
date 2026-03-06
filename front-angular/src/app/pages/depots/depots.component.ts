import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { DepotService } from '../../services/depot.service';
import { MagasinService } from '../../services/magasin.service';
import { Depot } from '../../models/depot.model';
import { Magasin } from '../../models/magasin.model';

@Component({
  selector: 'app-depots',
  templateUrl: './depots.component.html',
  styleUrls: ['./depots.component.css']
})
export class DepotsComponent implements OnInit {
  depots: Depot[] = [];
  magasins: Magasin[] = [];
  loading = true;
  showForm = false;
  editingDepot: Depot | null = null;
  formData: Depot = this.emptyForm();
  filterMagasinId: number | null = null;
  showStockModal = false;
  selectedDepot: Depot | null = null;

  constructor(
    private depotService: DepotService,
    private magasinService: MagasinService,
    private route: ActivatedRoute
  ) {}

  ngOnInit(): void {
    this.route.queryParams.subscribe(params => {
      this.filterMagasinId = params['magasinId'] ? +params['magasinId'] : null;
      this.loadData();
    });
    this.magasinService.getAll().subscribe(m => this.magasins = m);
  }

  emptyForm(): Depot {
    return { libelleDepot: '', code: '', nom: '', adresse: '', ville: '', codePostal: '', telephone: '', actif: true, magasinId: undefined, latitude: undefined, longitude: undefined, capaciteStockage: undefined };
  }

  loadData(): void {
    this.loading = true;
    const obs = this.filterMagasinId
      ? this.depotService.getByMagasinId(this.filterMagasinId)
      : this.depotService.getWithStocks();
    obs.subscribe({
      next: (data) => { this.depots = data; this.loading = false; },
      error: () => { this.loading = false; }
    });
  }

  openCreate(): void {
    this.editingDepot = null;
    this.formData = this.emptyForm();
    if (this.filterMagasinId) this.formData.magasinId = this.filterMagasinId;
    this.showForm = true;
  }

  openEdit(d: Depot): void {
    this.editingDepot = d;
    this.formData = { ...d };
    this.showForm = true;
  }

  closeForm(): void { this.showForm = false; this.editingDepot = null; }

  save(): void {
    if (!this.formData.libelleDepot) return;
    if (this.editingDepot && this.editingDepot.id) {
      this.depotService.update(this.editingDepot.id, this.formData).subscribe({
        next: () => { this.closeForm(); this.loadData(); }
      });
    } else {
      this.depotService.create(this.formData).subscribe({
        next: () => { this.closeForm(); this.loadData(); }
      });
    }
  }

  delete(d: Depot): void {
    if (!d.id) return;
    if (confirm(`Supprimer le dépôt "${d.libelleDepot}" ?`)) {
      this.depotService.delete(d.id).subscribe({ next: () => this.loadData() });
    }
  }

  openStockModal(depot: Depot): void {
    this.selectedDepot = depot;
    this.showStockModal = true;
  }

  closeStockModal(): void {
    this.showStockModal = false;
    this.selectedDepot = null;
  }

  getStockClass(stock: any): string {
    if (stock.quantiteDisponible <= 0) return 'stock-out';
    if (stock.quantiteMinimum && stock.quantiteDisponible <= stock.quantiteMinimum) return 'stock-low';
    return 'stock-ok';
  }
}
