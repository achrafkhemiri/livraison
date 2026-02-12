package com.example.backend.dto;

import lombok.*;
import java.math.BigDecimal;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProductStockInfoDTO {
    private Long produitId;
    private String produitNom;
    private String produitReference;
    private BigDecimal prixHT;
    private List<DepotStockDTO> depotStocks;
    private BigDecimal totalStock;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class DepotStockDTO {
        private Long depotId;
        private String depotNom;
        private Double depotLatitude;
        private Double depotLongitude;
        private BigDecimal quantiteDisponible;
    }
}
