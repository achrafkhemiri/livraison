package com.example.backend.dto;

import com.example.backend.model.Role;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UtilisateurDTO {
    private Long id;
    
    @NotBlank(message = "Le nom est obligatoire")
    private String nom;
    
    @NotBlank(message = "Le prénom est obligatoire")
    private String prenom;
    
    @NotBlank(message = "L'email est obligatoire")
    @Email(message = "Email invalide")
    private String email;
    
    private String telephone;
    
    @NotNull(message = "Le rôle est obligatoire")
    private Role role;
    
    private Long societeId;
    private String societeNom;
    
    // Position GPS du livreur
    private Double latitude;
    private Double longitude;
    private LocalDateTime dernierePositionAt;
    
    private Boolean actif;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
