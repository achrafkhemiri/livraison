import { Component, OnInit, OnDestroy, AfterViewInit } from '@angular/core';
import * as L from 'leaflet';
import { MapDataService } from '../../services/map-data.service';
import { SocieteService } from '../../services/societe.service';
import { MagasinService } from '../../services/magasin.service';
import { DepotService } from '../../services/depot.service';
import { UtilisateurService } from '../../services/utilisateur.service';
import { MapData, MapMarker } from '../../models/map-data.model';

@Component({
  selector: 'app-carte',
  templateUrl: './carte.component.html',
  styleUrls: ['./carte.component.css']
})
export class CarteComponent implements OnInit, AfterViewInit, OnDestroy {
  private map!: L.Map;
  private markersLayer = L.layerGroup();
  loading = true;
  error = '';

  showSocietes = true;
  showMagasins = true;
  showDepots = true;
  showLivreurs = true;

  societes: any[] = [];
  magasins: any[] = [];
  depots: any[] = [];
  livreurs: any[] = [];

  private refreshInterval: any;

  constructor(
    private mapDataService: MapDataService,
    private societeService: SocieteService,
    private magasinService: MagasinService,
    private depotService: DepotService,
    private utilisateurService: UtilisateurService
  ) {}

  ngOnInit(): void {}

  ngAfterViewInit(): void {
    this.initMap();
    this.loadAllData();
    // Refresh livreurs every 30s
    this.refreshInterval = setInterval(() => this.loadLivreurs(), 30000);
  }

  ngOnDestroy(): void {
    if (this.refreshInterval) clearInterval(this.refreshInterval);
    if (this.map) this.map.remove();
  }

  private initMap(): void {
    this.map = L.map('map', {
      center: [34.74, 10.76], // Sfax, Tunisia
      zoom: 13,
      zoomControl: true
    });

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap contributors',
      maxZoom: 19
    }).addTo(this.map);

    this.markersLayer.addTo(this.map);
  }

  loadAllData(): void {
    this.loading = true;
    // Try map-data endpoint first, fall back to individual calls
    this.mapDataService.getMapData().subscribe({
      next: (data: MapData) => {
        if (data.societe) this.societes = [data.societe];
        this.magasins = data.magasins || [];
        this.depots = data.depots || [];
        this.livreurs = data.livreurs || [];
        this.updateMarkers();
        this.loading = false;
      },
      error: () => {
        // Fallback: load individually
        this.loadSocietes();
        this.loadMagasins();
        this.loadDepots();
        this.loadLivreurs();
      }
    });
  }

  private loadSocietes(): void {
    this.societeService.getAll().subscribe({
      next: (data) => {
        this.societes = (data || []).filter((s: any) => s.latitude && s.longitude);
        this.updateMarkers();
        this.loading = false;
      },
      error: () => { this.loading = false; }
    });
  }

  private loadMagasins(): void {
    this.magasinService.getAll().subscribe({
      next: (data) => {
        this.magasins = (data || []).filter((m: any) => m.latitude && m.longitude);
        this.updateMarkers();
      }
    });
  }

  private loadDepots(): void {
    this.depotService.getAll().subscribe({
      next: (data) => {
        this.depots = (data || []).filter((d: any) => d.latitude && d.longitude);
        this.updateMarkers();
      }
    });
  }

  private loadLivreurs(): void {
    this.utilisateurService.getLivreurs().subscribe({
      next: (data) => {
        this.livreurs = (data || []).filter((l: any) => l.latitude && l.longitude);
        this.updateMarkers();
      }
    });
  }

  updateMarkers(): void {
    this.markersLayer.clearLayers();

    if (this.showSocietes) {
      this.societes.forEach(s => {
        const marker = L.marker([s.latitude, s.longitude], { icon: this.createIcon('#1A237E', 'business') });
        marker.bindPopup(`<b>Société</b><br>${s.nom || s.raisonSociale || 'Société'}<br>${s.adresse || ''}`);
        this.markersLayer.addLayer(marker);
      });
    }

    if (this.showMagasins) {
      this.magasins.forEach(m => {
        const marker = L.marker([m.latitude, m.longitude], { icon: this.createIcon('#2E7D32', 'store') });
        marker.bindPopup(`<b>Magasin</b><br>${m.nom || m.libelleMagasin || ''}<br>${m.adresse || ''}`);
        this.markersLayer.addLayer(marker);
      });
    }

    if (this.showDepots) {
      this.depots.forEach(d => {
        const marker = L.marker([d.latitude, d.longitude], { icon: this.createIcon('#E65100', 'warehouse') });
        marker.bindPopup(`<b>Dépôt</b><br>${d.nom || d.libelleDepot || ''}<br>${d.adresse || ''}`);
        this.markersLayer.addLayer(marker);
      });
    }

    if (this.showLivreurs) {
      this.livreurs.forEach(l => {
        const marker = L.marker([l.latitude, l.longitude], { icon: this.createIcon('#C62828', 'delivery_dining') });
        marker.bindPopup(`<b>Livreur</b><br>${l.prenom || ''} ${l.nom || ''}<br>${l.telephone || ''}`);
        this.markersLayer.addLayer(marker);
      });
    }

    // Fit bounds if markers
    if (this.markersLayer.getLayers().length > 0) {
      const group = L.featureGroup(this.markersLayer.getLayers());
      this.map.fitBounds(group.getBounds().pad(0.1));
    }
  }

  private createIcon(color: string, iconName: string): L.DivIcon {
    return L.divIcon({
      className: 'custom-marker',
      html: `<div style="background:${color};width:36px;height:36px;border-radius:50%;display:flex;align-items:center;justify-content:center;box-shadow:0 2px 8px rgba(0,0,0,0.3);border:3px solid white;">
               <span class="material-icons" style="font-size:18px;color:white;">${iconName}</span>
             </div>`,
      iconSize: [36, 36],
      iconAnchor: [18, 18],
      popupAnchor: [0, -20]
    });
  }

  toggleLayer(layer: string): void {
    switch (layer) {
      case 'societes': this.showSocietes = !this.showSocietes; break;
      case 'magasins': this.showMagasins = !this.showMagasins; break;
      case 'depots': this.showDepots = !this.showDepots; break;
      case 'livreurs': this.showLivreurs = !this.showLivreurs; break;
    }
    this.updateMarkers();
  }

  centerMap(): void {
    this.map.setView([34.74, 10.76], 13);
  }

  getMarkerCount(): number {
    return this.markersLayer.getLayers().length;
  }
}
