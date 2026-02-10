package com.example.backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "products")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Produit {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "name", nullable = false)
    private String name;
    
    @Column(name = "reference", nullable = false)
    private String reference;
    
    @Column(name = "seo_name")
    private String seoName;
    
    @Column(columnDefinition = "TEXT")
    private String description;
    
    @Column(columnDefinition = "LONGTEXT")
    private String tags;
    
    @Column(name = "price_uht", precision = 10, scale = 2)
    private BigDecimal priceUht;
    
    @Column(name = "id_tva")
    private Long idTva;
    
    @Column(name = "promotion_percentage")
    private Integer promotionPercentage;
    
    @Column(name = "stock")
    private Integer stock;
    
    @Column(name = "category_id")
    private Long categoryId;
    
    @Column(name = "images", columnDefinition = "LONGTEXT")
    private String images;
    
    @Column(name = "try_on_image")
    private String tryOnImage;
    
    @Column(name = "subcategory_id")
    private Long subcategoryId;
    
    @Column(name = "brand_id")
    private Long brandId;
    
    @Column(name = "shape_id")
    private Long shapeId;
    
    @Column(name = "version")
    private Integer version;
    
    // Remove creationUser/editUser because they may not exist in the database
    // @Column(name = "creationUser", insertable = false, updatable = false)
    // private Long creationUser;
    
    // @Column(name = "editUser", insertable = false, updatable = false)
    // private Long editUser;
    
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    // Helper methods for backward compatibility
    public String getDesignation() {
        return name;
    }
    
    public String getCode() {
        return reference;
    }
    
    public BigDecimal getPrixHT() {
        return priceUht;
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
