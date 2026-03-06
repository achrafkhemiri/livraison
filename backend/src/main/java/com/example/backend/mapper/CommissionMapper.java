package com.example.backend.mapper;

import com.example.backend.dto.CommissionConfigDTO;
import com.example.backend.dto.CommissionPaiementDTO;
import com.example.backend.model.CommissionConfig;
import com.example.backend.model.CommissionPaiement;
import org.springframework.stereotype.Component;

@Component
public class CommissionMapper {

    public CommissionConfigDTO toConfigDTO(CommissionConfig config) {
        if (config == null) return null;

        CommissionConfigDTO.CommissionConfigDTOBuilder builder = CommissionConfigDTO.builder()
                .id(config.getId())
                .montantFixe(config.getMontantFixe())
                .prixParKm(config.getPrixParKm())
                .bonus(config.getBonus())
                .inclureDistanceCollection(config.getInclureDistanceCollection())
                .actif(config.getActif())
                .dateDebut(config.getDateDebut())
                .dateFin(config.getDateFin())
                .createdAt(config.getCreatedAt())
                .updatedAt(config.getUpdatedAt());

        if (config.getLivreur() != null) {
            builder.livreurId(config.getLivreur().getId());
            String nom = config.getLivreur().getNom() != null ? config.getLivreur().getNom() : "";
            String prenom = config.getLivreur().getPrenom() != null ? config.getLivreur().getPrenom() : "";
            builder.livreurNom((prenom + " " + nom).trim());
        }

        return builder.build();
    }

    public CommissionPaiementDTO toPaiementDTO(CommissionPaiement paiement) {
        if (paiement == null) return null;

        CommissionPaiementDTO.CommissionPaiementDTOBuilder builder = CommissionPaiementDTO.builder()
                .id(paiement.getId())
                .montantFixe(paiement.getMontantFixe())
                .prixParKm(paiement.getPrixParKm())
                .distanceKm(paiement.getDistanceKm())
                .distanceCollectionKm(paiement.getDistanceCollectionKm())
                .distanceLivraisonKm(paiement.getDistanceLivraisonKm())
                .bonus(paiement.getBonus())
                .montantTotal(paiement.getMontantTotal())
                .livreurPaye(paiement.getLivreurPaye())
                .adminValide(paiement.getAdminValide())
                .datePaiementLivreur(paiement.getDatePaiementLivreur())
                .dateValidationAdmin(paiement.getDateValidationAdmin())
                .createdAt(paiement.getCreatedAt())
                .updatedAt(paiement.getUpdatedAt());

        if (paiement.getOrder() != null) {
            builder.orderId(paiement.getOrder().getId());
            builder.orderNumero(paiement.getOrder().getNumero());
        }

        if (paiement.getLivreur() != null) {
            builder.livreurId(paiement.getLivreur().getId());
            String nom = paiement.getLivreur().getNom() != null ? paiement.getLivreur().getNom() : "";
            String prenom = paiement.getLivreur().getPrenom() != null ? paiement.getLivreur().getPrenom() : "";
            builder.livreurNom((prenom + " " + nom).trim());
        }

        if (paiement.getCommissionConfig() != null) {
            builder.commissionConfigId(paiement.getCommissionConfig().getId());
        }

        return builder.build();
    }
}
