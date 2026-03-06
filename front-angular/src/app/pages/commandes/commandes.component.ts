import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { OrderService } from '../../services/order.service';
import { ClientService } from '../../services/client.service';
import { ProduitService } from '../../services/produit.service';
import { UtilisateurService } from '../../services/utilisateur.service';
import { Order, OrderItem, PageResponse } from '../../models/order.model';
import { Client, ProductStockInfo, DepotStock } from '../../models/client.model';
import { Produit } from '../../models/produit.model';
import { User } from '../../models/user.model';

/** A selected product item in the create-order form */
interface SelectedProductItem {
  produitId: number;
  produitNom: string;
  produitReference: string;
  prixHT: number;
  totalStock: number;
  depotStocks: DepotStock[];
  quantite: number;
}

/** Manual depot assignment for a product */
interface DepotAssignment {
  depotId: number;
  depotNom: string;
  depotLatitude?: number;
  depotLongitude?: number;
  quantite: number;
}

@Component({
  selector: 'app-commandes',
  templateUrl: './commandes.component.html',
  styleUrls: ['./commandes.component.css']
})
export class CommandesComponent implements OnInit {
  orders: Order[] = [];
  loading = true;
  totalElements = 0;
  totalPages = 0;
  currentPage = 0;
  pageSize = 10;
  searchTerm = '';
  statusFilter = '';
  dateFrom = '';
  dateTo = '';

  // Detail
  showDetail = false;
  selectedOrder: Order | null = null;

  // Create — clients from /api/users, products from /api/products-stock
  showCreateForm = false;
  clients: Client[] = [];
  productsStock: ProductStockInfo[] = [];
  loadingClients = false;
  loadingProducts = false;
  newOrder: Partial<Order> = {};
  selectedItems: SelectedProductItem[] = [];

  // Product picker modal
  showProductPicker = false;
  productSearchTerm = '';

  // Collection plan
  collectionType: 'auto' | 'manual' = 'auto';
  // manualAssignments: key = index in selectedItems, value = array of depot assignments
  manualAssignments: { [productIdx: number]: DepotAssignment[] } = {};

  // Assign
  showAssignModal = false;
  assignOrderId: number | null = null;
  recommendedLivreurs: any[] = [];
  loadingRecommendations = false;

  statusOptions = [
    { value: '', label: 'Tous' },
    { value: 'pending', label: 'En attente' },
    { value: 'assigned', label: 'Assignée' },
    { value: 'en_cours', label: 'En cours' },
    { value: 'processing', label: 'En traitement' },
    { value: 'shipped', label: 'Expédiée' },
    { value: 'delivered', label: 'Livrée' },
    { value: 'cancelled', label: 'Annulée' }
  ];

  constructor(
    private orderService: OrderService,
    private clientService: ClientService,
    private produitService: ProduitService,
    private utilisateurService: UtilisateurService,
    private route: ActivatedRoute
  ) {}

  ngOnInit(): void {
    this.route.queryParams.subscribe(params => {
      if (params['livreurId']) {
        this.orderService.getByLivreurId(+params['livreurId']).subscribe({
          next: (data) => { this.orders = data; this.totalElements = data.length; this.loading = false; }
        });
      } else {
        this.loadData();
      }
    });
  }

  loadData(): void {
    this.loading = true;
    this.orderService.searchOrders(this.currentPage, this.pageSize, this.searchTerm || undefined, this.statusFilter || undefined, this.dateFrom || undefined, this.dateTo || undefined).subscribe({
      next: (res) => {
        this.orders = res.content;
        this.totalElements = res.totalElements;
        this.totalPages = res.totalPages;
        this.loading = false;
      },
      error: () => { this.loading = false; }
    });
  }

  onSearchChange(): void { this.currentPage = 0; this.loadData(); }

  onStatusChange(status: string): void { this.statusFilter = status; this.currentPage = 0; this.loadData(); }

  onPageChange(page: number): void { this.currentPage = page; this.loadData(); }

  // Detail
  openDetail(order: Order): void { this.selectedOrder = order; this.showDetail = true; }
  closeDetail(): void { this.showDetail = false; this.selectedOrder = null; }

  // Status management
  getStatusLabel(status: string): string {
    const labels: { [key: string]: string } = { 'pending': 'En attente', 'assigned': 'Assignée', 'en_cours': 'En cours', 'processing': 'En traitement', 'shipped': 'Expédiée', 'delivered': 'Livrée', 'cancelled': 'Annulée' };
    return labels[status] || status;
  }

  getStatusClass(status: string): string { return 'status-' + status.replace('_', '-'); }

  canChangeStatus(order: Order, newStatus: string): boolean {
    const flow: { [key: string]: string[] } = {
      'pending': ['processing', 'cancelled'],
      'assigned': ['processing', 'cancelled'],
      'en_cours': ['processing', 'cancelled'],
      'processing': ['shipped', 'cancelled'],
      'shipped': ['delivered', 'cancelled']
    };
    return (flow[order.status] || []).includes(newStatus);
  }

  changeStatus(order: Order, newStatus: string): void {
    if (!order.id) return;
    this.orderService.updateStatus(order.id, newStatus).subscribe({
      next: () => {
        this.loadData();
        if (this.selectedOrder?.id === order.id) this.selectedOrder!.status = newStatus;
      }
    });
  }

  // Assign livreur
  openAssignModal(order: Order): void {
    if (!order.id) return;
    this.assignOrderId = order.id;
    this.showAssignModal = true;
    this.loadingRecommendations = true;
    this.recommendedLivreurs = [];
    this.orderService.recommendLivreurs(order.id).subscribe({
      next: (data) => { this.recommendedLivreurs = data; this.loadingRecommendations = false; },
      error: () => {
        this.utilisateurService.getLivreurs().subscribe(l => {
          this.recommendedLivreurs = l.map(liv => ({ livreurId: liv.id, livreurNom: (liv.prenom + ' ' + liv.nom).trim(), telephone: liv.telephone, distanceTotaleKm: null, tempsEstimeMinutes: null, commandesActives: null }));
          this.loadingRecommendations = false;
        });
      }
    });
  }

  assignLivreur(livreurId: number): void {
    if (!this.assignOrderId) return;
    this.orderService.assignLivreur(this.assignOrderId, livreurId).subscribe({
      next: () => { this.showAssignModal = false; this.assignOrderId = null; this.loadData(); }
    });
  }

  // ─── Create Order ───────────────────────────────────────────────
  openCreateForm(): void {
    this.newOrder = { status: 'pending' };
    this.selectedItems = [];
    this.manualAssignments = {};
    this.collectionType = 'auto';
    this.showCreateForm = true;
    this.loadingClients = true;
    this.loadingProducts = true;

    // Load clients from /api/users (like Flutter)
    this.clientService.getAll().subscribe({
      next: (c) => { this.clients = c; this.loadingClients = false; },
      error: () => { this.loadingClients = false; }
    });
    // Load products-stock from /api/products-stock (like Flutter)
    this.clientService.getProductsStock().subscribe({
      next: (p) => { this.productsStock = p; this.loadingProducts = false; },
      error: () => { this.loadingProducts = false; }
    });
  }

  closeCreateForm(): void { this.showCreateForm = false; }

  /** Client selected — auto-fill coordinates & address from UserDTO */
  onClientSelect(clientId: number): void {
    const client = this.clients.find(c => c.id === clientId);
    if (client) {
      this.newOrder.clientId = clientId;
      this.newOrder.adresseLivraison = client.address || client.adresse || '';
      this.newOrder.latitudeLivraison = client.latitude;
      this.newOrder.longitudeLivraison = client.longitude;
    }
  }

  /** Display name for a client (like Flutter: #id - name) */
  getClientDisplayName(c: Client): string {
    const name = c.name || c.nom || c.email || `Client #${c.id}`;
    return `#${c.id} - ${name}`;
  }

  // ─── Product Picker ─────────────────────────────────────────────
  openProductPicker(): void {
    this.productSearchTerm = '';
    this.showProductPicker = true;
  }

  closeProductPicker(): void { this.showProductPicker = false; }

  get filteredProductsStock(): ProductStockInfo[] {
    const term = this.productSearchTerm.toLowerCase();
    if (!term) return this.productsStock;
    return this.productsStock.filter(p =>
      p.produitNom.toLowerCase().includes(term) || p.produitReference.toLowerCase().includes(term)
    );
  }

  isProductSelected(produitId: number): boolean {
    return this.selectedItems.some(i => i.produitId === produitId);
  }

  selectProduct(product: ProductStockInfo): void {
    if (this.isProductSelected(product.produitId)) return;
    this.selectedItems = [...this.selectedItems, {
      produitId: product.produitId,
      produitNom: product.produitNom,
      produitReference: product.produitReference,
      prixHT: product.prixHT,
      totalStock: product.totalStock,
      depotStocks: product.depotStocks || [],
      quantite: 1
    }];
    this.showProductPicker = false;
  }

  removeProduct(index: number): void {
    this.selectedItems = this.selectedItems.filter((_, i) => i !== index);
    delete this.manualAssignments[index];
    // Re-index manual assignments
    const updated: { [k: number]: DepotAssignment[] } = {};
    for (const key of Object.keys(this.manualAssignments)) {
      const k = +key;
      if (k > index) { updated[k - 1] = this.manualAssignments[k]; }
      else { updated[k] = this.manualAssignments[k]; }
    }
    this.manualAssignments = updated;
  }

  getOrderTotal(): number {
    return this.selectedItems.reduce((sum, item) => sum + item.prixHT * item.quantite, 0);
  }

  // ─── Collection Plan (Manual Depot Assignments) ─────────────────
  toggleCollectionType(): void {
    this.collectionType = this.collectionType === 'auto' ? 'manual' : 'auto';
    if (this.collectionType === 'auto') this.manualAssignments = {};
  }

  setCollectionAuto(): void { this.collectionType = 'auto'; this.manualAssignments = {}; }
  setCollectionManual(): void { this.collectionType = 'manual'; }

  /** Check if a depot is already assigned for a product index */
  isDepotAssigned(productIdx: number, depotId: number): boolean {
    const assignments = this.manualAssignments[productIdx];
    if (!assignments || !assignments.length) return false;
    return assignments.some(a => a.depotId === depotId);
  }

  /** Add a depot assignment for a specific product */
  addDepotAssignment(productIdx: number, depot: DepotStock): void {
    if (!this.manualAssignments[productIdx]) {
      this.manualAssignments[productIdx] = [];
    }
    const existing = this.manualAssignments[productIdx].find(a => a.depotId === depot.depotId);
    if (existing) return; // already assigned
    this.manualAssignments[productIdx].push({
      depotId: depot.depotId,
      depotNom: depot.depotNom,
      depotLatitude: depot.depotLatitude,
      depotLongitude: depot.depotLongitude,
      quantite: 1
    });
  }

  removeDepotAssignment(productIdx: number, depotIdx: number): void {
    if (this.manualAssignments[productIdx]) {
      this.manualAssignments[productIdx].splice(depotIdx, 1);
      if (this.manualAssignments[productIdx].length === 0) delete this.manualAssignments[productIdx];
    }
  }

  /** Build collection plan JSON (like Flutter _buildManualCollectionPlan) */
  buildManualCollectionPlan(): string {
    const depotSteps: { [depotId: number]: any } = {};
    for (const productIdxStr of Object.keys(this.manualAssignments)) {
      const productIdx = +productIdxStr;
      const item = this.selectedItems[productIdx];
      if (!item) continue;
      for (const assignment of this.manualAssignments[productIdx]) {
        if (!depotSteps[assignment.depotId]) {
          depotSteps[assignment.depotId] = {
            depotId: assignment.depotId,
            depotNom: assignment.depotNom,
            depotLatitude: assignment.depotLatitude,
            depotLongitude: assignment.depotLongitude,
            items: [],
            orderIds: []
          };
        }
        depotSteps[assignment.depotId].items.push({
          produitId: item.produitId,
          produitNom: item.produitNom,
          quantite: assignment.quantite
        });
      }
    }
    const steps = Object.values(depotSteps).map((step: any, idx: number) => {
      step.step = idx + 1;
      return step;
    });
    return JSON.stringify(steps);
  }

  hasManualAssignments(): boolean {
    return Object.keys(this.manualAssignments).length > 0;
  }

  // ─── Submit Order ───────────────────────────────────────────────
  createOrder(): void {
    if (!this.newOrder.clientId || this.selectedItems.length === 0) return;

    const items: OrderItem[] = this.selectedItems.map(item => ({
      produitId: item.produitId,
      produitNom: item.produitNom,
      produitDesignation: item.produitNom,
      produitCode: item.produitReference,
      quantite: item.quantite,
      prixUnitaireHT: item.prixHT
    }));

    let collectionPlan: string | undefined;
    if (this.collectionType === 'manual' && this.hasManualAssignments()) {
      collectionPlan = this.buildManualCollectionPlan();
    }

    const order: Order = {
      clientId: this.newOrder.clientId!,
      status: 'pending',
      adresseLivraison: this.newOrder.adresseLivraison,
      latitudeLivraison: this.newOrder.latitudeLivraison,
      longitudeLivraison: this.newOrder.longitudeLivraison,
      notes: this.newOrder.notes,
      items,
      collectionPlan
    };
    this.orderService.create(order).subscribe({
      next: () => { this.closeCreateForm(); this.loadData(); }
    });
  }

  deleteOrder(order: Order): void {
    if (!order.id) return;
    if (confirm('Supprimer cette commande ?')) {
      this.orderService.delete(order.id).subscribe({ next: () => this.loadData() });
    }
  }

  /** Get livreur display name from recommendation response */
  getLivreurName(rec: any): string {
    // Backend returns flat: livreurNom, or fallback to nested livreur object
    if (rec.livreurNom) return rec.livreurNom;
    if (rec.livreur) {
      const l = rec.livreur;
      return ((l.prenom || '') + ' ' + (l.nom || '')).trim() || l.email || `Livreur #${l.id}`;
    }
    return ((rec.prenom || '') + ' ' + (rec.nom || '')).trim() || `Livreur #${rec.id || '?'}`;
  }

  getLivreurInitial(rec: any): string {
    const name = this.getLivreurName(rec);
    return name.charAt(0).toUpperCase();
  }

  getPageNumbers(): number[] {
    const pages: number[] = [];
    const start = Math.max(0, this.currentPage - 2);
    const end = Math.min(this.totalPages, start + 5);
    for (let i = start; i < end; i++) pages.push(i);
    return pages;
  }
}
