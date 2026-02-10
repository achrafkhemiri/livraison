package com.example.backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "depots")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Depot {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "libelle_depot", nullable = false)
    private String libelleDepot;
    
    @Column(nullable = false)
    private String code;
    
    @Column(nullable = false)
    private String nom;
    
    private String adresse;
    
    private String ville;
    
    @Column(name = "code_postal")
    private String codePostal;
    
    private String telephone;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "magasin_id", nullable = false)
    private Magasin magasin;
    
    // Coordonnées GPS pour le routing OSRM
    @Column(nullable = false)
    private Double latitude;
    
    @Column(nullable = false)
    private Double longitude;
    
    @Column(name = "capacite_stockage")
    private Integer capaciteStockage;
    
    private Boolean actif = true;
    
    @Column(nullable = false)
    private Integer version = 1;
    
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }
    
    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
