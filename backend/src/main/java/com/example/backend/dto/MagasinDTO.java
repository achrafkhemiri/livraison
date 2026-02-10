package com.example.backend.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.*;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MagasinDTO {
    private Long id;
    
    @NotBlank(message = "Le nom du magasin est obligatoire")
    private String nomMagasin;
    
    private String adresse;
    private String ville;
    private Long societeId;
    private String societeNom;
    private Double latitude;
    private Double longitude;
    private Integer version;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
