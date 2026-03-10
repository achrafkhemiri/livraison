package com.example.backend.dto;

import lombok.*;
import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BilanPeriodeDTO {
    private int annee;
    private int mois;
    private String periodeLabel;
    private long commandesLivrees;
    private BigDecimal revenu;
    private BigDecimal commissions;
    private BigDecimal resultat;
    private boolean rentable;
}
