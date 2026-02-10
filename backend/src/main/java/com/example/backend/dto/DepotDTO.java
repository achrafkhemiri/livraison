package com.example.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DepotDTO {
    private Long id;
    
    @NotBlank(message = "Le libellé dépôt est obligatoire")
    private String libelleDepot;
    
    @NotBlank(message = "Le code est obligatoire")
    private String code;
    
    @NotBlank(message = "Le nom est obligatoire")
    private String nom;
    
    private String adresse;
    private String ville;
    private String codePostal;
    private String telephone;
    
    @NotNull(message = "Le magasin est obligatoire")
    private Long magasinId;
    private String magasinNom;
    
    @NotNull(message = "La latitude est obligatoire")
    private Double latitude;
    
    @NotNull(message = "La longitude est obligatoire")
    private Double longitude;
    
    private Integer capaciteStockage;
    private Boolean actif;
    
    // Stock details for this depot
    private List<StockDTO> stocks;
}
