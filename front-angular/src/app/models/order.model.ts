export interface OrderItem {
  id?: number;
  produitId?: number;
  produitCode?: string;
  produitNom?: string;
  produitDesignation?: string;
  quantite: number;
  prixUnitaireHT?: number;
  prixUnitaireTTC?: number;
  remise?: number;
  tauxTva?: number;
  montantHT?: number;
  montantTVA?: number;
  montantTTC?: number;
}

export interface Order {
  id?: number;
  numero?: string;
  userId?: number;
  societeId?: number;
  societeNom?: string;
  clientId: number;
  clientNom?: string;
  clientPhone?: string;
  clientEmail?: string;
  clientLatitude?: number;
  clientLongitude?: number;
  livreurId?: number;
  livreurNom?: string;
  depotId?: number;
  depotNom?: string;
  status: string;
  montantHT?: number;
  montantTVA?: number;
  montantTTC?: number;
  adresseLivraison?: string;
  latitudeLivraison?: number;
  longitudeLivraison?: number;
  dateCommande?: string;
  dateLivraisonPrevue?: string;
  dateLivraisonEffective?: string;
  notes?: string;
  items?: OrderItem[];
  collected?: boolean;
  collectionPlan?: string;
  dateCollection?: string;
  proposedLivreurId?: number;
  proposedLivreurNom?: string;
  assignmentStatus?: string;
}

export interface PageResponse<T> {
  content: T[];
  page: number;
  size: number;
  totalElements: number;
  totalPages: number;
  first: boolean;
  last: boolean;
}
