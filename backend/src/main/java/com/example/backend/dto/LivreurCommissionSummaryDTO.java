package com.example.backend.dto;

import lombok.*;
import java.math.BigDecimal;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LivreurCommissionSummaryDTO {
    private Long livreurId;
    private String livreurNom;
    private long totalCommandes;
    private long commandesLivrees;
    private BigDecimal totalCommission;
    private BigDecimal totalPaye;
    private BigDecimal totalNonPaye;
    private long paiementsValides;
    private long paiementsEnAttente;
    private CommissionConfigDTO configActuelle;
    private List<CommissionPaiementDTO> paiements;
}
