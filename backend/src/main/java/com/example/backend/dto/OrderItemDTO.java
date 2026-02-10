package com.example.backend.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OrderItemDTO {
    private Long id;
    private Long orderId;
    
    @NotNull(message = "Le produit est obligatoire")
    private Long produitId;
    private String produitCode;
    private String produitDesignation;
    
    @NotNull(message = "La quantité est obligatoire")
    @Min(value = 1, message = "La quantité doit être supérieure à 0")
    private Integer quantite;
    
    private BigDecimal prixUnitaireHT;
    private BigDecimal prixUnitaireTTC;
    private BigDecimal tauxTva;
    private BigDecimal montantHT;
    private BigDecimal montantTVA;
    private BigDecimal montantTTC;
    private BigDecimal remise;
}
