import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { Client, ProductStockInfo } from '../models/client.model';

@Injectable({
  providedIn: 'root'
})
export class ClientService {
  /**  /api/users = table 'users' (consommateurs) — like Flutter */
  private apiUrl = `${environment.apiUrl}/users`;

  constructor(private http: HttpClient) {}

  getAll(): Observable<Client[]> {
    return this.http.get<Client[]>(this.apiUrl);
  }

  getById(id: number): Observable<Client> {
    return this.http.get<Client>(`${this.apiUrl}/${id}`);
  }

  /** Products with stock per depot — /api/products-stock */
  getProductsStock(): Observable<ProductStockInfo[]> {
    return this.http.get<ProductStockInfo[]>(`${environment.apiUrl}/products-stock`);
  }
}
