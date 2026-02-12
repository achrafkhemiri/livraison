package com.example.backend.dto;

import lombok.*;
import java.util.List;

/**
 * Plan de collecte optimisé pour un livreur.
 * Indique dans quels dépôts collecter quels produits pour une commande.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CollectionPlanDTO {
    private Long orderId;
    private String orderNumero;
    private List<DepotCollectionDTO> depotCollections;
    private boolean singleDepot; // true if all items can be collected from one depot

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class DepotCollectionDTO {
        private Long depotId;
        private String depotNom;
        private Double depotLatitude;
        private Double depotLongitude;
        private List<ItemCollectionDTO> items;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class ItemCollectionDTO {
        private Long produitId;
        private String produitNom;
        private Integer quantiteDemandee;
        private Integer quantiteDisponible;
    }
}
