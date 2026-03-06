import { Component, OnInit } from '@angular/core';
import { ProduitService } from '../../services/produit.service';
import { Produit } from '../../models/produit.model';

@Component({
  selector: 'app-produits',
  templateUrl: './produits.component.html',
  styleUrls: ['./produits.component.css']
})
export class ProduitsComponent implements OnInit {
  produits: Produit[] = [];
  filteredProduits: Produit[] = [];
  loading = true;
  showForm = false;
  editingProduit: Produit | null = null;
  formData: Produit = this.emptyForm();
  searchTerm = '';

  constructor(private produitService: ProduitService) {}

  ngOnInit(): void { this.loadData(); }

  emptyForm(): Produit {
    return { reference: '', designation: '', description: '', prixHT: 0, prixTTC: 0, categorie: '', unite: '', poids: undefined, actif: true };
  }

  loadData(): void {
    this.loading = true;
    this.produitService.getAll().subscribe({
      next: (data) => { this.produits = data; this.applyFilter(); this.loading = false; },
      error: () => { this.loading = false; }
    });
  }

  applyFilter(): void {
    const term = this.searchTerm.toLowerCase();
    this.filteredProduits = term
      ? this.produits.filter(p => p.designation.toLowerCase().includes(term) || p.reference.toLowerCase().includes(term))
      : [...this.produits];
  }

  openCreate(): void { this.editingProduit = null; this.formData = this.emptyForm(); this.showForm = true; }

  openEdit(p: Produit): void { this.editingProduit = p; this.formData = { ...p }; this.showForm = true; }

  closeForm(): void { this.showForm = false; this.editingProduit = null; }

  save(): void {
    if (!this.formData.reference || !this.formData.designation) return;
    if (this.editingProduit && this.editingProduit.id) {
      this.produitService.update(this.editingProduit.id, this.formData).subscribe({ next: () => { this.closeForm(); this.loadData(); } });
    } else {
      this.produitService.create(this.formData).subscribe({ next: () => { this.closeForm(); this.loadData(); } });
    }
  }

  delete(p: Produit): void {
    if (!p.id) return;
    if (confirm(`Supprimer le produit "${p.designation}" ?`)) {
      this.produitService.delete(p.id).subscribe({ next: () => this.loadData() });
    }
  }
}
