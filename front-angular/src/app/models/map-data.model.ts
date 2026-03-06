export interface MapData {
  societe?: MapMarker;
  magasins: MapMarker[];
  depots: MapMarker[];
  livreurs: MapMarker[];
}

export interface MapMarker {
  id: number;
  nom: string;
  type: string;
  latitude: number;
  longitude: number;
  adresse?: string;
  details?: any;
}
