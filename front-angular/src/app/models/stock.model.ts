export interface Stock {
  id?: number;
  depotId: number;
  depotNom?: string;
  produitId: number;
  produitCode?: string;
  produitDesignation?: string;
  quantiteDisponible: number;
  quantiteReservee?: number;
  quantiteMinimum?: number;
  quantiteMaximum?: number;
}
