package com.example.backend.dto;

import lombok.*;
import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BilanLivreurDTO {
    private int rang;
    private Long livreurId;
    private String livreurNom;
    private long commandesLivrees;
    private BigDecimal revenuGenere;
    private BigDecimal commissionPayee;
    private BigDecimal resultatNet;
    private boolean rentable;
}
