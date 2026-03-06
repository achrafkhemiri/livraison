export interface Magasin {
  id?: number;
  code: string;
  nom: string;
  adresse?: string;
  ville?: string;
  codePostal?: string;
  telephone?: string;
  email?: string;
  latitude?: number;
  longitude?: number;
  societeId?: number;
  societeNom?: string;
  actif: boolean;
}
