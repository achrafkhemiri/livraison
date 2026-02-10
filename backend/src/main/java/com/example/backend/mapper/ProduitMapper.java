package com.example.backend.mapper;

import com.example.backend.dto.ProduitDTO;
import com.example.backend.model.Produit;
import com.example.backend.model.Tva;
import com.example.backend.repository.TvaRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class ProduitMapper {
    
    @Autowired
    private TvaRepository tvaRepository;
    
    public ProduitDTO toDTO(Produit produit) {
        if (produit == null) return null;
        
        ProduitDTO.ProduitDTOBuilder builder = ProduitDTO.builder()
                .id(produit.getId())
                .code(produit.getReference())
                .designation(produit.getName())
                .description(produit.getDescription())
                .prixHT(produit.getPriceUht())
                .prixTTC(produit.getPriceUht()) // Same as HT for now
                .createdAt(produit.getCreatedAt())
                .updatedAt(produit.getUpdatedAt());
        
        // Load TVA if exists
        if (produit.getIdTva() != null) {
            try {
                Tva tva = tvaRepository.findById(produit.getIdTva()).orElse(null);
                if (tva != null) {
                    builder.tvaId(tva.getId())
                           .tvaLibelle(tva.getLibelle())
                           .tauxTva(tva.getTaux());
                }
            } catch (Exception e) {
                // TVA not available
            }
        }
        
        return builder.build();
    }
    
    public Produit toEntity(ProduitDTO dto) {
        if (dto == null) return null;
        
        return Produit.builder()
                .id(dto.getId())
                .reference(dto.getCode())
                .name(dto.getDesignation())
                .description(dto.getDescription())
                .priceUht(dto.getPrixHT())
                .build();
    }
    
    public void updateEntity(Produit produit, ProduitDTO dto, Tva tva) {
        if (dto.getCode() != null) produit.setReference(dto.getCode());
        if (dto.getDesignation() != null) produit.setName(dto.getDesignation());
        if (dto.getDescription() != null) produit.setDescription(dto.getDescription());
        if (dto.getPrixHT() != null) produit.setPriceUht(dto.getPrixHT());
        if (tva != null) produit.setIdTva(tva.getId());
    }
}
