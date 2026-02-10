package com.example.backend.dto;

import lombok.*;
import java.time.LocalDateTime;

/**
 * DTO pour les Clients/Consommateurs (table 'users' existante)
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserDTO {
    private Long id;
    private String name;
    private String email;
    private String phone;
    private String address;
    private Double latitude;
    private Double longitude;
    private String profileImage;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    
    // Informations additionnelles pour l'affichage
    private Integer orderCount;
}
