package com.example.backend.dto;

import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StockDTO {
    private Long id;
    
    @NotNull(message = "Le produit est obligatoire")
    private Long produitId;
    private String produitCode;
    private String produitDesignation;
    
    @NotNull(message = "Le dépôt est obligatoire")
    private Long depotId;
    private String depotNom;
    
    @NotNull(message = "La quantité disponible est obligatoire")
    private BigDecimal quantiteDisponible;
    
    private BigDecimal quantiteReservee;
    private BigDecimal quantiteMinimum;
    private BigDecimal quantiteMaximum;
    private LocalDateTime derniereEntree;
    private LocalDateTime derniereSortie;
    private LocalDateTime updatedAt;
}
