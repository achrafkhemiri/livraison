package com.example.backend.mapper;

import com.example.backend.dto.OrderItemDTO;
import com.example.backend.model.OrderItem;
import org.hibernate.Hibernate;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;

@Component
public class OrderItemMapper {
    
    public OrderItemDTO toDTO(OrderItem item) {
        if (item == null) return null;
        
        // Get actual quantity from the model helper method
        Integer qty = item.getActualQuantity();
        
        // Get actual price (prefers priceUht over prixUnitaireHT)
        BigDecimal priceHT = item.getActualPrice();
        BigDecimal priceTTC = item.getPrixUnitaireTTC();
        
        // Calculate montant if not set
        BigDecimal montantHT = item.getMontantHT();
        if (montantHT == null && priceHT != null) {
            montantHT = priceHT.multiply(BigDecimal.valueOf(qty));
        }
        
        OrderItemDTO.OrderItemDTOBuilder builder = OrderItemDTO.builder()
                .id(item.getId())
                .quantite(qty)
                .prixUnitaireHT(priceHT)
                .prixUnitaireTTC(priceTTC)
                .tauxTva(item.getTauxTva())
                .montantHT(montantHT)
                .montantTVA(item.getMontantTVA())
                .montantTTC(item.getMontantTTC() != null ? item.getMontantTTC() : montantHT)
                .remise(item.getRemise());
        
        if (item.getOrder() != null) {
            builder.orderId(item.getOrder().getId());
        }
        
        // Handle product safely
        try {
            if (item.getProduit() != null) {
                Hibernate.initialize(item.getProduit());
                builder.produitId(item.getProduit().getId())
                       .produitCode(item.getProduit().getReference())
                       .produitDesignation(item.getProduit().getName());
            }
        } catch (Exception e) {
            // Product not available
        }
        
        return builder.build();
    }
    
    public OrderItem toEntity(OrderItemDTO dto) {
        if (dto == null) return null;
        
        return OrderItem.builder()
                .id(dto.getId())
                .quantity(dto.getQuantite())
                .priceUht(dto.getPrixUnitaireHT())
                .prixUnitaireTTC(dto.getPrixUnitaireTTC())
                .tauxTva(dto.getTauxTva())
                .montantHT(dto.getMontantHT())
                .montantTVA(dto.getMontantTVA())
                .montantTTC(dto.getMontantTTC())
                .remise(dto.getRemise())
                .build();
    }
}
