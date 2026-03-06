export interface Societe {
  id?: number;
  raisonSociale: string;
  siret?: string;
  adresse?: string;
  ville?: string;
  codePostal?: string;
  telephone?: string;
  email?: string;
  actif: boolean;
  latitude?: number;
  longitude?: number;
}
