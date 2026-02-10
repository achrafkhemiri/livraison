package com.example.backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "magasins")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Magasin {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "nom_magasin", nullable = false)
    private String nomMagasin;
    
    private String adresse;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "societe_id")
    private Societe societe;
    
    private Double latitude;
    
    private Double longitude;
    
    private String ville;
    
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    @Column(nullable = false)
    private Integer version = 1;
    
    // Commented out because column may not exist in database
    // @Column(name = "creationUser")
    // private Long creationUser;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }
    
    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
    
    // Helper getter for nom (backwards compatibility)
    public String getNom() {
        return nomMagasin;
    }
    
    public void setNom(String nom) {
        this.nomMagasin = nom;
    }
}
