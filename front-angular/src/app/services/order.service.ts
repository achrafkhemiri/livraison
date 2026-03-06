import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { Order, PageResponse } from '../models/order.model';

@Injectable({
  providedIn: 'root'
})
export class OrderService {
  private apiUrl = `${environment.apiUrl}/orders`;

  constructor(private http: HttpClient) {}

  getAll(): Observable<Order[]> {
    return this.http.get<Order[]>(this.apiUrl);
  }

  getById(id: number): Observable<Order> {
    return this.http.get<Order>(`${this.apiUrl}/${id}`);
  }

  getByStatus(status: string): Observable<Order[]> {
    return this.http.get<Order[]>(`${this.apiUrl}/status/${status}`);
  }

  getByLivreurId(livreurId: number): Observable<Order[]> {
    return this.http.get<Order[]>(`${this.apiUrl}/livreur/${livreurId}`);
  }

  searchOrders(page: number, size: number, search?: string, status?: string, dateFrom?: string, dateTo?: string): Observable<PageResponse<Order>> {
    let params = new HttpParams()
      .set('page', page.toString())
      .set('size', size.toString());
    if (search) params = params.set('search', search);
    if (status) params = params.set('status', status);
    if (dateFrom) params = params.set('dateFrom', dateFrom);
    if (dateTo) params = params.set('dateTo', dateTo);
    return this.http.get<PageResponse<Order>>(`${this.apiUrl}/search`, { params });
  }

  create(order: Order): Observable<Order> {
    return this.http.post<Order>(this.apiUrl, order);
  }

  update(id: number, order: Order): Observable<Order> {
    return this.http.put<Order>(`${this.apiUrl}/${id}`, order);
  }

  updateStatus(id: number, status: string): Observable<Order> {
    return this.http.patch<Order>(`${this.apiUrl}/${id}/status`, null, {
      params: new HttpParams().set('status', status)
    });
  }

  assignLivreur(orderId: number, livreurId: number): Observable<Order> {
    return this.http.patch<Order>(`${this.apiUrl}/${orderId}/assign/${livreurId}`, null);
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }

  recommendLivreurs(orderId: number): Observable<any[]> {
    return this.http.get<any[]>(`${environment.apiUrl}/orders/${orderId}/recommend-livreurs`);
  }

  generateCollectionPlan(orderId: number): Observable<any> {
    return this.http.post<any>(`${environment.apiUrl}/orders/${orderId}/collection-plan`, null);
  }

  markAsCollected(orderId: number): Observable<Order> {
    return this.http.patch<Order>(`${environment.apiUrl}/orders/${orderId}/collected`, null);
  }
}
