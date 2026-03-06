export interface User {
  id: number;
  email: string;
  nom: string;
  prenom: string;
  role: string;
  telephone?: string;
  societeId?: number;
  societeNom?: string;
  latitude?: number;
  longitude?: number;
  dernierePositionAt?: string;
  actif: boolean;
  createdAt?: string;
}

export interface CreateUtilisateur {
  nom: string;
  prenom: string;
  email: string;
  password: string;
  role: string;
  telephone?: string;
  societeId?: number;
}
