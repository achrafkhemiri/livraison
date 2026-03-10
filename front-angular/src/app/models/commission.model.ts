export interface CommissionConfig {
  id?: number;
  livreurId: number;
  livreurNom?: string;
  montantFixe: number;
  prixParKm: number;
  bonus: number;
  inclureDistanceCollection?: boolean;
  actif?: boolean;
  dateDebut?: string;
  dateFin?: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface CommissionPaiement {
  id?: number;
  orderId?: number;
  orderNumero?: string;
  livreurId?: number;
  livreurNom?: string;
  commissionConfigId?: number;
  montantFixe?: number;
  prixParKm?: number;
  distanceKm?: number;
  distanceCollectionKm?: number;
  distanceLivraisonKm?: number;
  bonus?: number;
  montantTotal?: number;
  livreurPaye?: boolean;
  adminValide?: boolean;
  datePaiementLivreur?: string;
  dateValidationAdmin?: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface LivreurCommissionSummary {
  livreurId: number;
  livreurNom: string;
  totalCommandes: number;
  commandesLivrees: number;
  totalCommission: number;
  totalPaye: number;
  totalNonPaye: number;
  paiementsValides: number;
  paiementsEnAttente: number;
  configActuelle?: CommissionConfig;
  paiements: CommissionPaiement[];
}

export interface BilanPeriodeDTO {
  annee: number;
  mois: number;
  periodeLabel: string;
  commandesLivrees: number;
  revenu: number;
  commissions: number;
  resultat: number;
  rentable: boolean;
}

export interface BilanLivreurDTO {
  rang: number;
  livreurId: number;
  livreurNom: string;
  commandesLivrees: number;
  revenuGenere: number;
  commissionPayee: number;
  resultatNet: number;
  rentable: boolean;
}

export interface BilanDTO {
  fraisLivraisonUnitaire: number;
  periodeLabel: string;
  totalCommandesLivrees: number;
  totalRevenu: number;
  totalCommissions: number;
  resultatNet: number;
  rentable: boolean;
  bilanParMois: BilanPeriodeDTO[];
  bilanParLivreur: BilanLivreurDTO[];
}
