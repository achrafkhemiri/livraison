package com.example.backend.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.*;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SocieteDTO {
    private Long id;
    
    @NotBlank(message = "La raison sociale est obligatoire")
    private String raisonSociale;
    
    private String mf; // Matricule Fiscal
    private Double latitude;
    private Double longitude;
    private Integer version;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
