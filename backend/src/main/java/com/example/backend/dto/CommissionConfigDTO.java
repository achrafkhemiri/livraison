package com.example.backend.dto;

import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CommissionConfigDTO {
    private Long id;
    private Long livreurId;
    private String livreurNom;
    private BigDecimal montantFixe;
    private BigDecimal prixParKm;
    private BigDecimal bonus;
    private Boolean inclureDistanceCollection;
    private Boolean actif;
    private LocalDateTime dateDebut;
    private LocalDateTime dateFin;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
