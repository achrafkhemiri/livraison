package com.example.backend.dto;

import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CommissionPaiementDTO {
    private Long id;

    private Long orderId;
    private String orderNumero;

    private Long livreurId;
    private String livreurNom;

    private Long commissionConfigId;

    private BigDecimal montantFixe;
    private BigDecimal prixParKm;
    private BigDecimal distanceKm;
    private BigDecimal distanceCollectionKm;
    private BigDecimal distanceLivraisonKm;
    private BigDecimal bonus;
    private BigDecimal montantTotal;

    private Boolean livreurPaye;
    private Boolean adminValide;

    private LocalDateTime datePaiementLivreur;
    private LocalDateTime dateValidationAdmin;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
