package com.example.backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "societes")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Societe {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "raison_sociale", nullable = false)
    private String raisonSociale;
    
    // MF = Matricule Fiscal
    @Column(name = "mf", unique = true)
    private String mf;
    
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    @Column(name = "version", nullable = false)
    @lombok.Builder.Default
    private Integer version = 1;
    
    @Column(name = "creation_user")
    private Long creationUser;

    @Column(name = "edit_user")
    private Long editUser;

    @Column(name = "latitude")
    private Double latitude;

    @Column(name = "longitude")
    private Double longitude;
    
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
