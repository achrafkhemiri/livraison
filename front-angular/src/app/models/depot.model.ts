import { Stock } from './stock.model';

export interface Depot {
  id?: number;
  libelleDepot: string;
  code?: string;
  nom?: string;
  adresse?: string;
  ville?: string;
  codePostal?: string;
  telephone?: string;
  magasinId?: number;
  magasinNom?: string;
  latitude?: number;
  longitude?: number;
  capaciteStockage?: number;
  actif?: boolean;
  stocks?: Stock[];
}
