package com.example.backend.dto;

import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OrderDTO {
    private Long id;
    private String numero;
    
    private Long userId;
    private Long societeId;
    private String societeNom;
    
    @NotNull(message = "Le client est obligatoire")
    private Long clientId;
    private String clientNom;
    private String clientPhone;
    private String clientEmail;
    private Double clientLatitude;
    private Double clientLongitude;
    
    private Long livreurId;
    private String livreurNom;
    
    private Long depotId;
    private String depotNom;
    
    // status: pending, processing, shipped, delivered, cancelled, done
    private String status;
    private BigDecimal montantHT;
    private BigDecimal montantTVA;
    private BigDecimal montantTTC;
    private String adresseLivraison;
    private Double latitudeLivraison;
    private Double longitudeLivraison;
    private LocalDateTime dateCommande;
    private LocalDateTime dateLivraisonPrevue;
    private LocalDateTime dateLivraisonEffective;
    private String notes;
    private List<OrderItemDTO> items;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    
    // Collection fields
    private Boolean collected;
    private String collectionPlan;
    private LocalDateTime dateCollection;
}
