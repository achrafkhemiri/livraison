package com.example.backend.dto.auth;

import com.example.backend.model.Role;
import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LoginResponse {
    private String token;
    private String type = "Bearer";
    private Long id;
    private String email;
    private String nom;
    private String prenom;
    private Role role;
    private Long societeId;
    private String societeNom;
}
