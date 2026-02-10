package com.example.backend.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.*;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ClientDTO {
    private Long id;
    
    @NotBlank(message = "Le nom est obligatoire")
    private String nom;
    
    private String prenom;
    
    @Email(message = "Email invalide")
    private String email;
    
    private String telephone;
    private String adresse;
    private String ville;
    private String codePostal;
    private Double latitude;
    private Double longitude;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
