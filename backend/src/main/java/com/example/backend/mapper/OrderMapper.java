package com.example.backend.mapper;

import com.example.backend.dto.OrderDTO;
import com.example.backend.dto.OrderItemDTO;
import com.example.backend.model.Order;
import com.example.backend.model.Utilisateur;
import com.example.backend.model.User;
import com.example.backend.repository.UtilisateurRepository;
import org.hibernate.Hibernate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.stream.Collectors;

@Component
public class OrderMapper {
    
    @Autowired
    private OrderItemMapper orderItemMapper;
    
    @Autowired
    private UtilisateurRepository utilisateurRepository;
    
    public OrderDTO toDTO(Order order) {
        if (order == null) return null;
        
        OrderDTO.OrderDTOBuilder builder = OrderDTO.builder()
                .id(order.getId())
                .numero(order.getNumero())
                .userId(order.getUserId())
                .societeId(order.getSocieteId())
                .status(order.getStatus())
                .montantHT(order.getMontantHT())
                .montantTVA(order.getMontantTVA())
                .montantTTC(order.getMontantTTC())
                .adresseLivraison(order.getAdresseLivraison())
                .latitudeLivraison(order.getLatitudeLivraison())
                .longitudeLivraison(order.getLongitudeLivraison())
                .dateCommande(order.getDateCommande())
                .dateLivraisonPrevue(order.getDateLivraisonPrevue())
                .dateLivraisonEffective(order.getDateLivraisonEffective())
                .notes(order.getNotes())
                .collected(order.getCollected())
                .collectionPlan(order.getCollectionPlan())
                .dateCollection(order.getDateCollection())
                .proposedLivreurId(order.getProposedLivreurId())
                .assignmentStatus(order.getAssignmentStatus())
                .createdAt(order.getCreatedAt())
                .updatedAt(order.getUpdatedAt());
        
        // Get societe name if available
        try {
            if (order.getSociete() != null) {
                Hibernate.initialize(order.getSociete());
                builder.societeNom(order.getSociete().getRaisonSociale());
            }
        } catch (Exception e) {
            // Ignore
        }
        
        // Utilise user_id et User (clients consommateurs) de la table 'users'
        // Handle user safely - may not exist in database
        try {
            User user = order.getUser();
            if (user != null) {
                try {
                    Hibernate.initialize(user);
                    builder.clientId(user.getId())
                           .clientNom(user.getName() != null ? user.getName() : "Client #" + user.getId())
                           .clientPhone(user.getPhone())
                           .clientEmail(user.getEmail())
                           .clientLatitude(user.getLatitude())
                           .clientLongitude(user.getLongitude());
                    // Coordonnées du client pour la carte si pas de coordonnées de livraison
                    if (order.getLatitudeLivraison() == null && user.getLatitude() != null) {
                        builder.latitudeLivraison(user.getLatitude())
                               .longitudeLivraison(user.getLongitude());
                    }
                    if (order.getAdresseLivraison() == null && user.getAddress() != null) {
                        builder.adresseLivraison(user.getAddress());
                    }
                } catch (Exception e) {
                    // User reference exists but user not in database
                    if (order.getUserId() != null) {
                        builder.clientId(order.getUserId())
                               .clientNom("Client #" + order.getUserId());
                    }
                }
            } else if (order.getUserId() != null) {
                builder.clientId(order.getUserId())
                       .clientNom("Client #" + order.getUserId());
            }
        } catch (Exception e) {
            // Fall back to userId if user loading fails
            if (order.getUserId() != null) {
                builder.clientId(order.getUserId())
                       .clientNom("Client #" + order.getUserId());
            }
        }
        
        if (order.getLivreur() != null) {
            builder.livreurId(order.getLivreur().getId());
            String nom = order.getLivreur().getNom() != null ? order.getLivreur().getNom() : "";
            String prenom = order.getLivreur().getPrenom() != null ? order.getLivreur().getPrenom() : "";
            builder.livreurNom((nom + " " + prenom).trim());
        }
        
        // Resolve proposed livreur name
        if (order.getProposedLivreurId() != null) {
            try {
                utilisateurRepository.findById(order.getProposedLivreurId()).ifPresent(u -> {
                    String pNom = u.getNom() != null ? u.getNom() : "";
                    String pPrenom = u.getPrenom() != null ? u.getPrenom() : "";
                    builder.proposedLivreurNom((pNom + " " + pPrenom).trim());
                });
            } catch (Exception e) {
                // Ignore
            }
        }
        
        if (order.getDepot() != null) {
            builder.depotId(order.getDepot().getId());
            String depotName = order.getDepot().getNom();
            if (depotName == null) {
                depotName = order.getDepot().getLibelleDepot();
            }
            builder.depotNom(depotName != null ? depotName : "Dépôt #" + order.getDepot().getId());
        }
        
        if (order.getItems() != null) {
            builder.items(order.getItems().stream()
                    .map(orderItemMapper::toDTO)
                    .collect(Collectors.toList()));
        }
        
        return builder.build();
    }
    
    public Order toEntity(OrderDTO dto) {
        if (dto == null) return null;
        
        return Order.builder()
                .id(dto.getId())
                .numero(dto.getNumero())
                .userId(dto.getUserId())
                .status(dto.getStatus())
                .montantHT(dto.getMontantHT())
                .montantTVA(dto.getMontantTVA())
                .montantTTC(dto.getMontantTTC())
                .adresseLivraison(dto.getAdresseLivraison())
                .latitudeLivraison(dto.getLatitudeLivraison())
                .longitudeLivraison(dto.getLongitudeLivraison())
                .dateCommande(dto.getDateCommande())
                .dateLivraisonPrevue(dto.getDateLivraisonPrevue())
                .dateLivraisonEffective(dto.getDateLivraisonEffective())
                .notes(dto.getNotes())
                .build();
    }
}
