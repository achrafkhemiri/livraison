package com.example.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProduitDTO {
    private Long id;
    
    @NotBlank(message = "Le code est obligatoire")
    private String code;
    
    @NotBlank(message = "La désignation est obligatoire")
    private String designation;
    
    private String description;
    
    @NotNull(message = "Le prix HT est obligatoire")
    private BigDecimal prixHT;
    
    private BigDecimal prixTTC;
    private Long tvaId;
    private String tvaLibelle;
    private BigDecimal tauxTva;
    private String unite;
    private String categorie;
    private Boolean actif;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
