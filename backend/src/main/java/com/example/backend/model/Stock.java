package com.example.backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "stocks")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Stock {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id")
    private Produit produit;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "depot_id")
    private Depot depot;
    
    @Column(name = "quantity")
    private Integer quantity;
    
    @Column(name = "quantite_disponible")
    private BigDecimal quantiteDisponible;
    
    @Column(name = "quantite_reservee")
    private BigDecimal quantiteReservee;
    
    @Column(name = "quantite_minimum")
    private BigDecimal quantiteMinimum;
    
    @Column(name = "quantite_maximum")
    private BigDecimal quantiteMaximum;
    
    @Column(name = "derniere_entree")
    private LocalDateTime derniereEntree;
    
    @Column(name = "derniere_sortie")
    private LocalDateTime derniereSortie;
    
    @Column(name = "version")
    private Integer version;
    
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    // Helper to get actual quantity (prefer quantity column over quantiteDisponible)
    public BigDecimal getActualQuantity() {
        if (quantity != null && quantity > 0) {
            return BigDecimal.valueOf(quantity);
        }
        return quantiteDisponible != null ? quantiteDisponible : BigDecimal.ZERO;
    }
    
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
