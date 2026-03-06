import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { Societe } from '../models/societe.model';

@Injectable({
  providedIn: 'root'
})
export class SocieteService {
  private apiUrl = `${environment.apiUrl}/societes`;

  constructor(private http: HttpClient) {}

  getAll(): Observable<Societe[]> {
    return this.http.get<Societe[]>(this.apiUrl);
  }

  getById(id: number): Observable<Societe> {
    return this.http.get<Societe>(`${this.apiUrl}/${id}`);
  }

  getMySociete(): Observable<Societe> {
    return this.http.get<Societe>(`${this.apiUrl}/me`);
  }

  create(societe: Societe): Observable<Societe> {
    return this.http.post<Societe>(this.apiUrl, societe);
  }

  update(id: number, societe: Societe): Observable<Societe> {
    return this.http.put<Societe>(`${this.apiUrl}/${id}`, societe);
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }
}
