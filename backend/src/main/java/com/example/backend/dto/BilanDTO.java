package com.example.backend.dto;

import lombok.*;
import java.math.BigDecimal;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BilanDTO {
    private BigDecimal fraisLivraisonUnitaire;
    private String periodeLabel;
    private long totalCommandesLivrees;
    private BigDecimal totalRevenu;        // fraisLivraison × commandesLivrees
    private BigDecimal totalCommissions;   // sum(montantTotal) payées
    private BigDecimal resultatNet;        // revenu − commissions
    private boolean rentable;

    private List<BilanPeriodeDTO> bilanParMois;
    private List<BilanLivreurDTO> bilanParLivreur;
}
