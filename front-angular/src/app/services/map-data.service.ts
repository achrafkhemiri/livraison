import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { MapData } from '../models/map-data.model';

@Injectable({
  providedIn: 'root'
})
export class MapDataService {
  private apiUrl = environment.apiUrl;

  constructor(private http: HttpClient) {}

  getMapData(): Observable<MapData> {
    return this.http.get<MapData>(`${this.apiUrl}/map-data`);
  }

  getProductsStock(): Observable<any[]> {
    return this.http.get<any[]>(`${this.apiUrl}/products-stock`);
  }
}
