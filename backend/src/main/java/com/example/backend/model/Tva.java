package com.example.backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "tva")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Tva {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false, unique = true, precision = 5, scale = 2)
    private BigDecimal rate;
    
    @Column(nullable = false)
    private String code;
    
    @Column(nullable = false)
    private String libelle;
    
    @Column(nullable = false, precision = 5, scale = 2)
    private BigDecimal taux;
    
    private Boolean actif = true;
    
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (rate == null && taux != null) {
            rate = taux;
        }
    }
    
    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
