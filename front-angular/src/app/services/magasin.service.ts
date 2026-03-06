import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { Magasin } from '../models/magasin.model';

@Injectable({
  providedIn: 'root'
})
export class MagasinService {
  private apiUrl = `${environment.apiUrl}/magasins`;

  constructor(private http: HttpClient) {}

  getAll(): Observable<Magasin[]> {
    return this.http.get<Magasin[]>(this.apiUrl);
  }

  getById(id: number): Observable<Magasin> {
    return this.http.get<Magasin>(`${this.apiUrl}/${id}`);
  }

  getBySocieteId(societeId: number): Observable<Magasin[]> {
    return this.http.get<Magasin[]>(`${this.apiUrl}/societe/${societeId}`);
  }

  create(magasin: Magasin): Observable<Magasin> {
    return this.http.post<Magasin>(this.apiUrl, magasin);
  }

  update(id: number, magasin: Magasin): Observable<Magasin> {
    return this.http.put<Magasin>(`${this.apiUrl}/${id}`, magasin);
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }
}
