import { Component, OnInit } from '@angular/core';
import { CommissionService } from '../../services/commission.service';
import {
  CommissionConfig,
  CommissionPaiement,
  LivreurCommissionSummary,
  BilanDTO
} from '../../models/commission.model';

@Component({
  selector: 'app-commissions',
  templateUrl: './commissions.component.html',
  styleUrls: ['./commissions.component.css']
})
export class CommissionsComponent implements OnInit {
  // Tabs
  activeTab: 'summary' | 'paiements' | 'configs' | 'bilan' = 'summary';

  // Data
  summaries: LivreurCommissionSummary[] = [];
  paiements: CommissionPaiement[] = [];
  configs: CommissionConfig[] = [];
  loading = true;

  // Filters (summary tab - client-side)
  searchTerm = '';

  // Paiements pagination/search (server-side)
  pSearchTerm = '';
  pFilterStatus = '';
  pCurrentPage = 0;
  pPageSize = 10;
  pTotalPages = 0;
  pTotalElements = 0;

  // Configs pagination/search (server-side)
  cSearchTerm = '';
  cCurrentPage = 0;
  cPageSize = 10;
  cTotalPages = 0;
  cTotalElements = 0;

  // Detail modal pagination/search (server-side)
  detailPaiements: CommissionPaiement[] = [];
  dSearchTerm = '';
  dFilterStatus = '';
  dCurrentPage = 0;
  dPageSize = 10;
  dTotalPages = 0;
  dTotalElements = 0;

  // Detail modal
  showDetail = false;
  selectedSummary: LivreurCommissionSummary | null = null;
  detailLoading = false;
  recalculating = false;

  // Config modal
  showConfigForm = false;
  editingConfig: CommissionConfig | null = null;
  configForm: Partial<CommissionConfig> = {};
  configLivreurNom = '';

  // Bilan
  bilanData: BilanDTO | null = null;
  bilanLoading = false;
  bilanAnnee: number = 0;
  bilanMois: number = 0;
  bilanAnneesDisponibles: number[] = [];

  // Frais livraison (loaded once for résultat column)
  fraisLivraison: number = 0;

  constructor(private commissionService: CommissionService) {}

  ngOnInit(): void {
    this.loadSummaries();
    this.commissionService.getBilan().subscribe({
      next: (data) => { this.fraisLivraison = data.fraisLivraisonUnitaire || 0; }
    });
  }

  // ── Tab switching ───────────────────────────────────────
  switchTab(tab: 'summary' | 'paiements' | 'configs' | 'bilan'): void {
    this.activeTab = tab;
    if (tab === 'summary') this.loadSummaries();
    else if (tab === 'paiements') { this.pCurrentPage = 0; this.loadPaiements(); }
    else if (tab === 'configs') { this.cCurrentPage = 0; this.loadConfigs(); }
    else if (tab === 'bilan') this.loadBilan();
  }

  // ── Data loading ────────────────────────────────────────
  loadSummaries(): void {
    this.loading = true;
    this.commissionService.getAllSummaries().subscribe({
      next: (data) => { this.summaries = data; this.loading = false; },
      error: () => { this.loading = false; }
    });
  }

  loadPaiements(): void {
    this.loading = true;
    this.commissionService.searchPaiements(
      this.pCurrentPage, this.pPageSize,
      this.pSearchTerm || undefined, this.pFilterStatus || undefined
    ).subscribe({
      next: (res) => {
        this.paiements = res.content;
        this.pTotalPages = res.totalPages;
        this.pTotalElements = res.totalElements;
        this.loading = false;
      },
      error: () => { this.loading = false; }
    });
  }

  loadConfigs(): void {
    this.loading = true;
    this.commissionService.searchConfigs(
      this.cCurrentPage, this.cPageSize,
      this.cSearchTerm || undefined
    ).subscribe({
      next: (res) => {
        this.configs = res.content;
        this.cTotalPages = res.totalPages;
        this.cTotalElements = res.totalElements;
        this.loading = false;
      },
      error: () => { this.loading = false; }
    });
  }

  loadDetailPaiements(): void {
    if (!this.selectedSummary) return;
    this.detailLoading = true;
    this.commissionService.searchPaiementsByLivreur(
      this.selectedSummary.livreurId,
      this.dCurrentPage, this.dPageSize,
      this.dSearchTerm || undefined, this.dFilterStatus || undefined
    ).subscribe({
      next: (res) => {
        this.detailPaiements = res.content;
        this.dTotalPages = res.totalPages;
        this.dTotalElements = res.totalElements;
        this.detailLoading = false;
      },
      error: () => { this.detailLoading = false; }
    });
  }

  // ── Paiements pagination ───────────────────────────────
  onPSearchChange(): void { this.pCurrentPage = 0; this.loadPaiements(); }
  onPStatusChange(status: string): void { this.pFilterStatus = status; this.pCurrentPage = 0; this.loadPaiements(); }
  onPPageChange(page: number): void { this.pCurrentPage = page; this.loadPaiements(); }
  onPPageSizeChange(): void { this.pCurrentPage = 0; this.loadPaiements(); }
  getPPageNumbers(): number[] {
    const start = Math.max(0, this.pCurrentPage - 2);
    const end = Math.min(this.pTotalPages, start + 5);
    const pages: number[] = [];
    for (let i = start; i < end; i++) pages.push(i);
    return pages;
  }

  // ── Configs pagination ─────────────────────────────────
  onCSearchChange(): void { this.cCurrentPage = 0; this.loadConfigs(); }
  onCPageChange(page: number): void { this.cCurrentPage = page; this.loadConfigs(); }
  onCPageSizeChange(): void { this.cCurrentPage = 0; this.loadConfigs(); }
  getCPageNumbers(): number[] {
    const start = Math.max(0, this.cCurrentPage - 2);
    const end = Math.min(this.cTotalPages, start + 5);
    const pages: number[] = [];
    for (let i = start; i < end; i++) pages.push(i);
    return pages;
  }

  // ── Detail pagination ──────────────────────────────────
  onDSearchChange(): void { this.dCurrentPage = 0; this.loadDetailPaiements(); }
  onDStatusChange(status: string): void { this.dFilterStatus = status; this.dCurrentPage = 0; this.loadDetailPaiements(); }
  onDPageChange(page: number): void { this.dCurrentPage = page; this.loadDetailPaiements(); }
  onDPageSizeChange(): void { this.dCurrentPage = 0; this.loadDetailPaiements(); }

  // ── Detail ──────────────────────────────────────────────
  openDetail(summary: LivreurCommissionSummary): void {
    this.selectedSummary = summary;
    this.showDetail = true;
    this.dCurrentPage = 0;
    this.dSearchTerm = '';
    this.dFilterStatus = '';
    this.detailPaiements = [];
    this.loadDetailPaiements();
  }

  closeDetail(): void {
    this.showDetail = false;
    this.selectedSummary = null;
    this.detailPaiements = [];
  }

  getDPageNumbers(): number[] {
    const start = Math.max(0, this.dCurrentPage - 2);
    const end = Math.min(this.dTotalPages, start + 5);
    const pages: number[] = [];
    for (let i = start; i < end; i++) pages.push(i);
    return pages;
  }

  // ── Config CRUD ─────────────────────────────────────────
  openConfigCreate(livreurId?: number, livreurNom?: string): void {
    this.editingConfig = null;
    this.configForm = {
      livreurId: livreurId || undefined,
      montantFixe: 0,
      prixParKm: 0,
      bonus: 0,
      inclureDistanceCollection: false
    };
    this.configLivreurNom = livreurNom || '';
    this.showConfigForm = true;
  }

  openConfigEdit(config: CommissionConfig): void {
    this.editingConfig = config;
    this.configForm = { ...config };
    this.configLivreurNom = config.livreurNom || '';
    this.showConfigForm = true;
  }

  closeConfigForm(): void {
    this.showConfigForm = false;
    this.editingConfig = null;
  }

  saveConfig(): void {
    if (!this.configForm.livreurId) return;
    const payload: CommissionConfig = {
      livreurId: this.configForm.livreurId!,
      montantFixe: this.configForm.montantFixe || 0,
      prixParKm: this.configForm.prixParKm || 0,
      bonus: this.configForm.bonus || 0,
      inclureDistanceCollection: this.configForm.inclureDistanceCollection || false
    };

    if (this.editingConfig && this.editingConfig.id) {
      this.commissionService.updateConfig(this.editingConfig.id, payload).subscribe({
        next: () => { this.closeConfigForm(); this.refreshCurrentTab(); }
      });
    } else {
      this.commissionService.createConfig(payload).subscribe({
        next: () => { this.closeConfigForm(); this.refreshCurrentTab(); }
      });
    }
  }

  deactivateConfig(config: CommissionConfig): void {
    if (!config.id || !confirm('Désactiver cette configuration de commission ?')) return;
    this.commissionService.deactivateConfig(config.id).subscribe({
      next: () => this.refreshCurrentTab()
    });
  }

  // ── Paiement actions ────────────────────────────────────
  toggleLivreurPaye(p: CommissionPaiement): void {
    if (!p.id) return;
    const obs = p.livreurPaye
      ? this.commissionService.unmarkLivreurPaye(p.id)
      : this.commissionService.markLivreurPaye(p.id);
    obs.subscribe({ next: () => this.refreshCurrentTab() });
  }

  toggleAdminValide(p: CommissionPaiement): void {
    if (!p.id) return;
    const obs = p.adminValide
      ? this.commissionService.unmarkAdminValide(p.id)
      : this.commissionService.markAdminValide(p.id);
    obs.subscribe({ next: () => this.refreshCurrentTab() });
  }

  // ── Utilities ───────────────────────────────────────────
  refreshCurrentTab(): void {
    if (this.activeTab === 'summary') this.loadSummaries();
    else if (this.activeTab === 'paiements') this.loadPaiements();
    else if (this.activeTab === 'configs') this.loadConfigs();
    else if (this.activeTab === 'bilan') this.loadBilan();
    // Refresh detail if open
    if (this.showDetail && this.selectedSummary) {
      this.loadDetailPaiements();
    }
  }

  get filteredSummaries(): LivreurCommissionSummary[] {
    if (!this.searchTerm) return this.summaries;
    const term = this.searchTerm.toLowerCase();
    return this.summaries.filter(s => s.livreurNom.toLowerCase().includes(term));
  }

  getPaymentStatusLabel(p: CommissionPaiement): string {
    if (p.livreurPaye && p.adminValide) return 'Validé';
    if (p.livreurPaye) return 'Livreur payé';
    return 'En attente';
  }

  getPaymentStatusClass(p: CommissionPaiement): string {
    if (p.livreurPaye && p.adminValide) return 'status-delivered';
    if (p.livreurPaye) return 'status-shipped';
    return 'status-pending';
  }

  recalculateDistances(): void {
    this.recalculating = true;
    this.commissionService.recalculateAllDistances().subscribe({
      next: (result) => {
        this.recalculating = false;
        this.refreshCurrentTab();
        alert(`${result.recalculated} commission(s) recalculée(s) avec succès.`);
      },
      error: () => {
        this.recalculating = false;
        alert('Erreur lors du recalcul des distances.');
      }
    });
  }

  // ── Bilan ───────────────────────────────────────────────
  loadBilan(): void {
    this.bilanLoading = true;
    // Load available years if not yet loaded
    if (this.bilanAnneesDisponibles.length === 0) {
      this.commissionService.getAnneesDisponibles().subscribe({
        next: (annees) => { this.bilanAnneesDisponibles = annees; }
      });
    }
    const annee = this.bilanAnnee > 0 ? this.bilanAnnee : undefined;
    const mois = this.bilanMois > 0 ? this.bilanMois : undefined;
    this.commissionService.getBilan(annee, mois).subscribe({
      next: (data) => { this.bilanData = data; this.bilanLoading = false; },
      error: () => { this.bilanLoading = false; }
    });
  }

  onBilanAnneeChange(): void {
    if (this.bilanAnnee === 0) this.bilanMois = 0;
    this.loadBilan();
  }

  onBilanMoisChange(): void {
    this.loadBilan();
  }
}
