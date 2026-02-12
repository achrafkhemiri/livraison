package com.example.backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;

@Entity
@Table(name = "order_items")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OrderItem {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false)
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    private Order order;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id")
    private Produit produit;
    
    @Column(name = "quantite")
    private Integer quantity;
    
    @Column(name = "price_uht", precision = 10, scale = 2)
    private BigDecimal priceUht;
    
    @Column(name = "id_tva")
    private Long idTva;
    
    @Column(name = "promotion_percentage")
    private Integer promotionPercentage;
    
    @Column(name = "prix_unitaire_ht", precision = 10, scale = 2)
    private BigDecimal prixUnitaireHT;
    
    @Column(name = "prix_unitaire_ttc", precision = 10, scale = 2)
    private BigDecimal prixUnitaireTTC;
    
    @Column(name = "taux_tva", precision = 5, scale = 2)
    private BigDecimal tauxTva;
    
    @Column(name = "montant_ht", precision = 10, scale = 2)
    private BigDecimal montantHT;
    
    @Column(name = "montant_tva", precision = 10, scale = 2)
    private BigDecimal montantTVA;
    
    @Column(name = "montant_ttc", precision = 10, scale = 2)
    private BigDecimal montantTTC;
    
    @Column(name = "remise", precision = 38, scale = 2)
    private BigDecimal remise;
    
    @Column(name = "version")
    private Integer version = 1;
    
    // Helper to get actual quantity
    public Integer getActualQuantity() {
        return quantity != null ? quantity : 0;
    }
    
    // Helper to get actual price
    public BigDecimal getActualPrice() {
        if (priceUht != null) return priceUht;
        if (prixUnitaireHT != null) return prixUnitaireHT;
        return BigDecimal.ZERO;
    }
}
