package com.example.backend.mapper;

import com.example.backend.dto.StockDTO;
import com.example.backend.model.Stock;
import org.hibernate.Hibernate;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;

@Component
public class StockMapper {
    
    public StockDTO toDTO(Stock stock) {
        if (stock == null) return null;
        
        // Use getActualQuantity() to get the real quantity
        BigDecimal qty = stock.getActualQuantity();
        
        StockDTO.StockDTOBuilder builder = StockDTO.builder()
                .id(stock.getId())
                .quantiteDisponible(qty)
                .quantiteReservee(stock.getQuantiteReservee())
                .quantiteMinimum(stock.getQuantiteMinimum())
                .quantiteMaximum(stock.getQuantiteMaximum())
                .derniereEntree(stock.getDerniereEntree())
                .derniereSortie(stock.getDerniereSortie())
                .updatedAt(stock.getUpdatedAt());
        
        try {
            if (stock.getProduit() != null) {
                Hibernate.initialize(stock.getProduit());
                builder.produitId(stock.getProduit().getId())
                       .produitCode(stock.getProduit().getReference())
                       .produitDesignation(stock.getProduit().getName());
            }
        } catch (Exception e) {
            // Produit not available
        }
        
        try {
            if (stock.getDepot() != null) {
                Hibernate.initialize(stock.getDepot());
                builder.depotId(stock.getDepot().getId())
                       .depotNom(stock.getDepot().getNom());
            }
        } catch (Exception e) {
            // Depot not available
        }
        
        return builder.build();
    }
    
    public Stock toEntity(StockDTO dto) {
        if (dto == null) return null;
        
        return Stock.builder()
                .id(dto.getId())
                .quantiteDisponible(dto.getQuantiteDisponible())
                .quantiteReservee(dto.getQuantiteReservee())
                .quantiteMinimum(dto.getQuantiteMinimum())
                .quantiteMaximum(dto.getQuantiteMaximum())
                .derniereEntree(dto.getDerniereEntree())
                .derniereSortie(dto.getDerniereSortie())
                .build();
    }
    
    public void updateEntity(Stock stock, StockDTO dto) {
        if (dto.getQuantiteDisponible() != null) stock.setQuantiteDisponible(dto.getQuantiteDisponible());
        if (dto.getQuantiteReservee() != null) stock.setQuantiteReservee(dto.getQuantiteReservee());
        if (dto.getQuantiteMinimum() != null) stock.setQuantiteMinimum(dto.getQuantiteMinimum());
        if (dto.getQuantiteMaximum() != null) stock.setQuantiteMaximum(dto.getQuantiteMaximum());
    }
}
