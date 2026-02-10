package com.example.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TvaDTO {
    private Long id;
    
    @NotBlank(message = "Le code est obligatoire")
    private String code;
    
    @NotBlank(message = "Le libellé est obligatoire")
    private String libelle;
    
    @NotNull(message = "Le taux est obligatoire")
    private BigDecimal taux;
    
    private BigDecimal rate;
    
    private Boolean actif;
}
