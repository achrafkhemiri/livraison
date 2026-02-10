package com.example.backend.mapper;

import com.example.backend.dto.MagasinDTO;
import com.example.backend.model.Magasin;
import org.springframework.stereotype.Component;

@Component
public class MagasinMapper {
    
    public MagasinDTO toDTO(Magasin magasin) {
        if (magasin == null) return null;
        
        MagasinDTO.MagasinDTOBuilder builder = MagasinDTO.builder()
                .id(magasin.getId())
                .nomMagasin(magasin.getNomMagasin())
                .adresse(magasin.getAdresse())
                .ville(magasin.getVille())
                .latitude(magasin.getLatitude())
                .longitude(magasin.getLongitude())
                .version(magasin.getVersion())
                .createdAt(magasin.getCreatedAt())
                .updatedAt(magasin.getUpdatedAt());
        
        if (magasin.getSociete() != null) {
            builder.societeId(magasin.getSociete().getId())
                   .societeNom(magasin.getSociete().getRaisonSociale());
        }
        
        return builder.build();
    }
    
    public Magasin toEntity(MagasinDTO dto) {
        if (dto == null) return null;
        
        return Magasin.builder()
                .id(dto.getId())
                .nomMagasin(dto.getNomMagasin())
                .adresse(dto.getAdresse())
                .ville(dto.getVille())
                .latitude(dto.getLatitude())
                .longitude(dto.getLongitude())
                .version(dto.getVersion() != null ? dto.getVersion() : 1)
                .build();
    }
    
    public void updateEntity(Magasin magasin, MagasinDTO dto) {
        if (dto.getNomMagasin() != null) magasin.setNomMagasin(dto.getNomMagasin());
        if (dto.getAdresse() != null) magasin.setAdresse(dto.getAdresse());
        if (dto.getVille() != null) magasin.setVille(dto.getVille());
        if (dto.getLatitude() != null) magasin.setLatitude(dto.getLatitude());
        if (dto.getLongitude() != null) magasin.setLongitude(dto.getLongitude());
    }
}
