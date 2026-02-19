package com.example.backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "orders")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Order {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    // Champs obligatoires de la table existante
    @Column(name = "user_id", nullable = false)
    private Long userId;
    
    @Column(name = "total_amount", precision = 10, scale = 2, nullable = false)
    private BigDecimal totalAmount = BigDecimal.ZERO;
    
    @Column(name = "shipping_address", nullable = false, columnDefinition = "LONGTEXT")
    private String shippingAddress;
    
    @Column(name = "payment_method", nullable = false)
    private String paymentMethod = "cash";
    
    @Column(name = "payment_status", nullable = false)
    private String paymentStatus = "pending";
    
    @Column(name = "order_number", unique = true, nullable = false)
    private String orderNumber;
    
    @Column(unique = true, nullable = false)
    private String numero;
    
    // User (client consommateur) - table 'users' existante
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", insertable = false, updatable = false)
    private User user;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "livreur_id")
    private Utilisateur livreur;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "depot_id")
    private Depot depot;
    
    // Societe pour filtrer les commandes par société
    @Column(name = "societe_id")
    private Long societeId;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "societe_id", insertable = false, updatable = false)
    private Societe societe;
    
    // status utilise les valeurs MySQL: pending, processing, shipped, delivered, cancelled, done
    @Column(nullable = false)
    private String status = "pending";
    
    @Column(name = "montant_ht", precision = 10, scale = 2)
    private BigDecimal montantHT;
    
    @Column(name = "montant_tva", precision = 10, scale = 2)
    private BigDecimal montantTVA;
    
    @Column(name = "montant_ttc", precision = 10, scale = 2)
    private BigDecimal montantTTC;
    
    @Column(name = "adresse_livraison")
    private String adresseLivraison;
    
    @Column(name = "latitude_livraison")
    private Double latitudeLivraison;
    
    @Column(name = "longitude_livraison")
    private Double longitudeLivraison;
    
    @Column(name = "date_commande")
    private LocalDateTime dateCommande;
    
    @Column(name = "date_livraison_prevue")
    private LocalDateTime dateLivraisonPrevue;
    
    @Column(name = "date_livraison_effective")
    private LocalDateTime dateLivraisonEffective;
    
    private String notes;
    
    // Collection fields
    @Column(name = "collected")
    private Boolean collected;
    
    @Column(name = "collection_plan", columnDefinition = "LONGTEXT")
    private String collectionPlan;
    
    @Column(name = "date_collection")
    private LocalDateTime dateCollection;
    
    // Livreur assignment workflow: proposed → accepted/rejected
    @Column(name = "proposed_livreur_id")
    private Long proposedLivreurId;
    
    @Column(name = "assignment_status", length = 20)
    private String assignmentStatus;
    // Values: null (not proposed), "proposed", "accepted", "rejected"
    
    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<OrderItem> items = new ArrayList<>();
    
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (dateCommande == null) {
            dateCommande = LocalDateTime.now();
        }
    }
    
    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
    
    public void addItem(OrderItem item) {
        items.add(item);
        item.setOrder(this);
    }
    
    public void removeItem(OrderItem item) {
        items.remove(item);
        item.setOrder(null);
    }
}
