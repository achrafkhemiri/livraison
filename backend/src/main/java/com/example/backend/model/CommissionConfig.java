package com.example.backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "commission_configs")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CommissionConfig {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "livreur_id", nullable = false)
    private Utilisateur livreur;

    @Column(name = "montant_fixe", precision = 10, scale = 3, nullable = false)
    private BigDecimal montantFixe;

    @Column(name = "prix_par_km", precision = 10, scale = 3, nullable = false)
    private BigDecimal prixParKm;

    @Column(name = "bonus", precision = 10, scale = 3)
    @Builder.Default
    private BigDecimal bonus = BigDecimal.ZERO;

    @Column(name = "inclure_distance_collection", nullable = false)
    @Builder.Default
    private Boolean inclureDistanceCollection = false;

    @Column(name = "actif", nullable = false)
    @Builder.Default
    private Boolean actif = true;

    @Column(name = "date_debut", nullable = false)
    private LocalDateTime dateDebut;

    @Column(name = "date_fin")
    private LocalDateTime dateFin;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (dateDebut == null) {
            dateDebut = LocalDateTime.now();
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
