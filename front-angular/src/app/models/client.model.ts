export interface Client {
  id?: number;
  name?: string;
  nom?: string;
  prenom?: string;
  email?: string;
  phone?: string;
  telephone?: string;
  address?: string;
  adresse?: string;
  ville?: string;
  codePostal?: string;
  latitude?: number;
  longitude?: number;
  profileImage?: string;
  actif?: boolean;
  orderCount?: number;
}

/** Product with stock info from /api/products-stock */
export interface ProductStockInfo {
  produitId: number;
  produitNom: string;
  produitReference: string;
  prixHT: number;
  totalStock: number;
  depotStocks: DepotStock[];
}

export interface DepotStock {
  depotId: number;
  depotNom: string;
  depotLatitude?: number;
  depotLongitude?: number;
  quantiteDisponible: number;
}
