package com.example.backend.mapper;

import com.example.backend.dto.TvaDTO;
import com.example.backend.model.Tva;
import org.springframework.stereotype.Component;

@Component
public class TvaMapper {
    
    public TvaDTO toDTO(Tva tva) {
        if (tva == null) return null;
        
        return TvaDTO.builder()
                .id(tva.getId())
                .code(tva.getCode())
                .libelle(tva.getLibelle())
                .taux(tva.getTaux())
                .rate(tva.getRate())
                .actif(tva.getActif())
                .build();
    }
    
    public Tva toEntity(TvaDTO dto) {
        if (dto == null) return null;
        
        return Tva.builder()
                .id(dto.getId())
                .code(dto.getCode())
                .libelle(dto.getLibelle())
                .taux(dto.getTaux())
                .rate(dto.getRate() != null ? dto.getRate() : dto.getTaux())
                .actif(dto.getActif() != null ? dto.getActif() : true)
                .build();
    }
    
    public void updateEntity(Tva tva, TvaDTO dto) {
        if (dto.getCode() != null) tva.setCode(dto.getCode());
        if (dto.getLibelle() != null) tva.setLibelle(dto.getLibelle());
        if (dto.getTaux() != null) {
            tva.setTaux(dto.getTaux());
            tva.setRate(dto.getTaux());
        }
        if (dto.getRate() != null) tva.setRate(dto.getRate());
        if (dto.getActif() != null) tva.setActif(dto.getActif());
    }
}
