package com.example.backend.mapper;

import com.example.backend.dto.SocieteDTO;
import com.example.backend.model.Societe;
import org.springframework.stereotype.Component;

@Component
public class SocieteMapper {
    
    public SocieteDTO toDTO(Societe societe) {
        if (societe == null) return null;
        
        return SocieteDTO.builder()
                .id(societe.getId())
                .raisonSociale(societe.getRaisonSociale())
                .mf(societe.getMf())
                .version(societe.getVersion())
                .createdAt(societe.getCreatedAt())
                .updatedAt(societe.getUpdatedAt())
                .build();
    }
    
    public Societe toEntity(SocieteDTO dto) {
        if (dto == null) return null;
        
        return Societe.builder()
                .id(dto.getId())
                .raisonSociale(dto.getRaisonSociale())
                .mf(dto.getMf())
                .version(dto.getVersion() != null ? dto.getVersion() : 1)
                .build();
    }
    
    public void updateEntity(Societe societe, SocieteDTO dto) {
        if (dto.getRaisonSociale() != null) societe.setRaisonSociale(dto.getRaisonSociale());
        if (dto.getMf() != null) societe.setMf(dto.getMf());
    }
}
