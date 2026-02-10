package com.example.backend.mapper;

import com.example.backend.dto.DepotDTO;
import com.example.backend.model.Depot;
import org.hibernate.Hibernate;
import org.springframework.stereotype.Component;

@Component
public class DepotMapper {
    
    public DepotDTO toDTO(Depot depot) {
        if (depot == null) return null;
        
        DepotDTO.DepotDTOBuilder builder = DepotDTO.builder()
                .id(depot.getId())
                .libelleDepot(depot.getLibelleDepot())
                .code(depot.getCode())
                .nom(depot.getNom())
                .adresse(depot.getAdresse())
                .ville(depot.getVille())
                .codePostal(depot.getCodePostal())
                .telephone(depot.getTelephone())
                .latitude(depot.getLatitude())
                .longitude(depot.getLongitude())
                .capaciteStockage(depot.getCapaciteStockage())
                .actif(depot.getActif());
        
        // Gestion sécurisée du Magasin lazy-loadé
        try {
            if (depot.getMagasin() != null && Hibernate.isInitialized(depot.getMagasin())) {
                builder.magasinId(depot.getMagasin().getId())
                       .magasinNom(depot.getMagasin().getNom());
            } else if (depot.getMagasin() != null) {
                // Essayer d'accéder au proxy, capturer l'exception si le magasin n'existe pas
                builder.magasinId(depot.getMagasin().getId());
                try {
                    builder.magasinNom(depot.getMagasin().getNom());
                } catch (Exception e) {
                    builder.magasinNom("N/A");
                }
            }
        } catch (Exception e) {
            // Ignorer si le magasin n'existe plus
        }
        
        return builder.build();
    }
    
    public Depot toEntity(DepotDTO dto) {
        if (dto == null) return null;
        
        return Depot.builder()
                .id(dto.getId())
                .libelleDepot(dto.getLibelleDepot())
                .code(dto.getCode())
                .nom(dto.getNom())
                .adresse(dto.getAdresse())
                .ville(dto.getVille())
                .codePostal(dto.getCodePostal())
                .telephone(dto.getTelephone())
                .latitude(dto.getLatitude())
                .longitude(dto.getLongitude())
                .capaciteStockage(dto.getCapaciteStockage())
                .actif(dto.getActif() != null ? dto.getActif() : true)
                .build();
    }
    
    public void updateEntity(Depot depot, DepotDTO dto) {
        if (dto.getLibelleDepot() != null) depot.setLibelleDepot(dto.getLibelleDepot());
        if (dto.getCode() != null) depot.setCode(dto.getCode());
        if (dto.getNom() != null) depot.setNom(dto.getNom());
        if (dto.getAdresse() != null) depot.setAdresse(dto.getAdresse());
        if (dto.getVille() != null) depot.setVille(dto.getVille());
        if (dto.getCodePostal() != null) depot.setCodePostal(dto.getCodePostal());
        if (dto.getTelephone() != null) depot.setTelephone(dto.getTelephone());
        if (dto.getLatitude() != null) depot.setLatitude(dto.getLatitude());
        if (dto.getLongitude() != null) depot.setLongitude(dto.getLongitude());
        if (dto.getCapaciteStockage() != null) depot.setCapaciteStockage(dto.getCapaciteStockage());
        if (dto.getActif() != null) depot.setActif(dto.getActif());
    }
}
