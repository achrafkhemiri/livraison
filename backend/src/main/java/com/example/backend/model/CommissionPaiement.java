package com.example.backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "commission_paiements")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CommissionPaiement {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false, columnDefinition = "bigint unsigned")
    private Order order;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "livreur_id", nullable = false)
    private Utilisateur livreur;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "commission_config_id")
    private CommissionConfig commissionConfig;

    @Column(name = "montant_fixe", precision = 10, scale = 3, nullable = false)
    private BigDecimal montantFixe;

    @Column(name = "prix_par_km", precision = 10, scale = 3, nullable = false)
    private BigDecimal prixParKm;

    @Column(name = "distance_km", precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal distanceKm = BigDecimal.ZERO;

    @Column(name = "distance_collection_km", precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal distanceCollectionKm = BigDecimal.ZERO;

    @Column(name = "distance_livraison_km", precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal distanceLivraisonKm = BigDecimal.ZERO;

    @Column(name = "bonus", precision = 10, scale = 3)
    @Builder.Default
    private BigDecimal bonus = BigDecimal.ZERO;

    @Column(name = "montant_total", precision = 10, scale = 3, nullable = false)
    private BigDecimal montantTotal;

    @Column(name = "livreur_paye", nullable = false)
    @Builder.Default
    private Boolean livreurPaye = false;

    @Column(name = "admin_valide", nullable = false)
    @Builder.Default
    private Boolean adminValide = false;

    @Column(name = "date_paiement_livreur")
    private LocalDateTime datePaiementLivreur;

    @Column(name = "date_validation_admin")
    private LocalDateTime dateValidationAdmin;

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
