import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { Depot } from '../models/depot.model';

@Injectable({
  providedIn: 'root'
})
export class DepotService {
  private apiUrl = `${environment.apiUrl}/depots`;

  constructor(private http: HttpClient) {}

  getAll(): Observable<Depot[]> {
    return this.http.get<Depot[]>(this.apiUrl);
  }

  getWithStocks(): Observable<Depot[]> {
    return this.http.get<Depot[]>(`${this.apiUrl}/with-stocks`);
  }

  getById(id: number): Observable<Depot> {
    return this.http.get<Depot>(`${this.apiUrl}/${id}`);
  }

  getByMagasinId(magasinId: number): Observable<Depot[]> {
    return this.http.get<Depot[]>(`${this.apiUrl}/magasin/${magasinId}`);
  }

  create(depot: Depot): Observable<Depot> {
    return this.http.post<Depot>(this.apiUrl, depot);
  }

  update(id: number, depot: Depot): Observable<Depot> {
    return this.http.put<Depot>(`${this.apiUrl}/${id}`, depot);
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }
}
