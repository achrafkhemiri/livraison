export interface Produit {
  id?: number;
  reference: string;
  designation: string;
  description?: string;
  prixHT: number;
  prixTTC: number;
  tvaId?: number;
  tauxTva?: number;
  categorie?: string;
  unite?: string;
  poids?: number;
  actif: boolean;
}
