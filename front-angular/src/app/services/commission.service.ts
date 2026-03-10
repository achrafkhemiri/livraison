import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { CommissionConfig, CommissionPaiement, LivreurCommissionSummary, BilanDTO } from '../models/commission.model';
import { PageResponse } from '../models/order.model';

@Injectable({
  providedIn: 'root'
})
export class CommissionService {
  private apiUrl = `${environment.apiUrl}/commissions`;

  constructor(private http: HttpClient) {}

  // ── Config ──────────────────────────────────────────────

  createConfig(config: CommissionConfig): Observable<CommissionConfig> {
    return this.http.post<CommissionConfig>(`${this.apiUrl}/configs`, config);
  }

  updateConfig(id: number, config: CommissionConfig): Observable<CommissionConfig> {
    return this.http.put<CommissionConfig>(`${this.apiUrl}/configs/${id}`, config);
  }

  getConfigById(id: number): Observable<CommissionConfig> {
    return this.http.get<CommissionConfig>(`${this.apiUrl}/configs/${id}`);
  }

  getActiveConfigByLivreur(livreurId: number): Observable<CommissionConfig> {
    return this.http.get<CommissionConfig>(`${this.apiUrl}/configs/livreur/${livreurId}`);
  }

  getConfigHistory(livreurId: number): Observable<CommissionConfig[]> {
    return this.http.get<CommissionConfig[]>(`${this.apiUrl}/configs/livreur/${livreurId}/history`);
  }

  getAllActiveConfigs(): Observable<CommissionConfig[]> {
    return this.http.get<CommissionConfig[]>(`${this.apiUrl}/configs/active`);
  }

  searchConfigs(page: number, size: number, search?: string): Observable<PageResponse<CommissionConfig>> {
    let params = new HttpParams()
      .set('page', page.toString())
      .set('size', size.toString());
    if (search) params = params.set('search', search);
    return this.http.get<PageResponse<CommissionConfig>>(`${this.apiUrl}/configs/search`, { params });
  }

  deactivateConfig(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/configs/${id}`);
  }

  // ── Paiements ───────────────────────────────────────────

  generateCommission(orderId: number, distanceKm?: number): Observable<CommissionPaiement> {
    let params = new HttpParams();
    if (distanceKm != null) {
      params = params.set('distanceKm', distanceKm.toString());
    }
    return this.http.post<CommissionPaiement>(`${this.apiUrl}/paiements/generate/${orderId}`, null, { params });
  }

  getAllPaiements(): Observable<CommissionPaiement[]> {
    return this.http.get<CommissionPaiement[]>(`${this.apiUrl}/paiements`);
  }

  getPaiementById(id: number): Observable<CommissionPaiement> {
    return this.http.get<CommissionPaiement>(`${this.apiUrl}/paiements/${id}`);
  }

  getPaiementByOrder(orderId: number): Observable<CommissionPaiement> {
    return this.http.get<CommissionPaiement>(`${this.apiUrl}/paiements/order/${orderId}`);
  }

  getPaiementsByLivreur(livreurId: number): Observable<CommissionPaiement[]> {
    return this.http.get<CommissionPaiement[]>(`${this.apiUrl}/paiements/livreur/${livreurId}`);
  }

  searchPaiements(page: number, size: number, search?: string, status?: string): Observable<PageResponse<CommissionPaiement>> {
    let params = new HttpParams()
      .set('page', page.toString())
      .set('size', size.toString());
    if (search) params = params.set('search', search);
    if (status) params = params.set('status', status);
    return this.http.get<PageResponse<CommissionPaiement>>(`${this.apiUrl}/paiements/search`, { params });
  }

  searchPaiementsByLivreur(livreurId: number, page: number, size: number, search?: string, status?: string): Observable<PageResponse<CommissionPaiement>> {
    let params = new HttpParams()
      .set('page', page.toString())
      .set('size', size.toString());
    if (search) params = params.set('search', search);
    if (status) params = params.set('status', status);
    return this.http.get<PageResponse<CommissionPaiement>>(`${this.apiUrl}/paiements/livreur/${livreurId}/search`, { params });
  }

  markLivreurPaye(paiementId: number): Observable<CommissionPaiement> {
    return this.http.put<CommissionPaiement>(`${this.apiUrl}/paiements/${paiementId}/livreur-paye`, null);
  }

  markAdminValide(paiementId: number): Observable<CommissionPaiement> {
    return this.http.put<CommissionPaiement>(`${this.apiUrl}/paiements/${paiementId}/admin-valide`, null);
  }

  unmarkLivreurPaye(paiementId: number): Observable<CommissionPaiement> {
    return this.http.put<CommissionPaiement>(`${this.apiUrl}/paiements/${paiementId}/unmark-livreur-paye`, null);
  }

  unmarkAdminValide(paiementId: number): Observable<CommissionPaiement> {
    return this.http.put<CommissionPaiement>(`${this.apiUrl}/paiements/${paiementId}/unmark-admin-valide`, null);
  }

  // ── Summaries ───────────────────────────────────────────

  getAllSummaries(): Observable<LivreurCommissionSummary[]> {
    return this.http.get<LivreurCommissionSummary[]>(`${this.apiUrl}/summary`);
  }

  getLivreurSummary(livreurId: number): Observable<LivreurCommissionSummary> {
    return this.http.get<LivreurCommissionSummary>(`${this.apiUrl}/summary/${livreurId}`);
  }

  recalculateAllDistances(): Observable<{ recalculated: number }> {
    return this.http.put<{ recalculated: number }>(`${this.apiUrl}/paiements/recalculate-all`, null);
  }

  // ── Bilan ───────────────────────────────────────────────

  getBilan(annee?: number, mois?: number): Observable<BilanDTO> {
    let params = new HttpParams();
    if (annee != null && annee > 0) params = params.set('annee', annee.toString());
    if (mois != null && mois > 0) params = params.set('mois', mois.toString());
    return this.http.get<BilanDTO>(`${this.apiUrl}/bilan`, { params });
  }

  getAnneesDisponibles(): Observable<number[]> {
    return this.http.get<number[]>(`${this.apiUrl}/bilan/annees`);
  }
}
