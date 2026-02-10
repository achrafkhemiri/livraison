package com.example.backend.mapper;

import com.example.backend.dto.CreateUtilisateurDTO;
import com.example.backend.dto.UtilisateurDTO;
import com.example.backend.model.Utilisateur;
import org.springframework.stereotype.Component;

@Component
public class UtilisateurMapper {
    
    public UtilisateurDTO toDTO(Utilisateur utilisateur) {
        if (utilisateur == null) return null;
        
        UtilisateurDTO.UtilisateurDTOBuilder builder = UtilisateurDTO.builder()
                .id(utilisateur.getId())
                .nom(utilisateur.getNom())
                .prenom(utilisateur.getPrenom())
                .email(utilisateur.getEmail())
                .telephone(utilisateur.getTelephone())
                .role(utilisateur.getRole())
                .latitude(utilisateur.getLatitude())
                .longitude(utilisateur.getLongitude())
                .dernierePositionAt(utilisateur.getDernierePositionAt())
                .actif(utilisateur.getActif())
                .createdAt(utilisateur.getCreatedAt())
                .updatedAt(utilisateur.getUpdatedAt());
        
        if (utilisateur.getSociete() != null) {
            builder.societeId(utilisateur.getSociete().getId())
                   .societeNom(utilisateur.getSociete().getRaisonSociale());
        }
        
        return builder.build();
    }
    
    public Utilisateur toEntity(CreateUtilisateurDTO dto) {
        if (dto == null) return null;
        
        return Utilisateur.builder()
                .nom(dto.getNom())
                .prenom(dto.getPrenom())
                .email(dto.getEmail())
                .telephone(dto.getTelephone())
                .password(dto.getPassword())
                .role(dto.getRole())
                .actif(true)
                .build();
    }
    
    public void updateEntity(Utilisateur utilisateur, UtilisateurDTO dto) {
        if (dto.getNom() != null) utilisateur.setNom(dto.getNom());
        if (dto.getPrenom() != null) utilisateur.setPrenom(dto.getPrenom());
        if (dto.getEmail() != null) utilisateur.setEmail(dto.getEmail());
        if (dto.getTelephone() != null) utilisateur.setTelephone(dto.getTelephone());
        if (dto.getRole() != null) utilisateur.setRole(dto.getRole());
        if (dto.getActif() != null) utilisateur.setActif(dto.getActif());
    }
}
