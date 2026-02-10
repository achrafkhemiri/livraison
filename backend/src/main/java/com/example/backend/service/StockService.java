package com.example.backend.service;

import com.example.backend.dto.StockDTO;
import java.math.BigDecimal;
import java.util.List;

public interface StockService {
    List<StockDTO> findAll();
    List<StockDTO> findByDepotId(Long depotId);
    List<StockDTO> findByProduitId(Long produitId);
    List<StockDTO> findLowStock();
    List<StockDTO> findBySocieteId(Long societeId);
    List<StockDTO> findLowStockBySocieteId(Long societeId);
    StockDTO findById(Long id);
    StockDTO findByProduitAndDepot(Long produitId, Long depotId);
    StockDTO create(StockDTO stockDTO);
    StockDTO update(Long id, StockDTO stockDTO);
    StockDTO addStock(Long produitId, Long depotId, BigDecimal quantity);
    StockDTO removeStock(Long produitId, Long depotId, BigDecimal quantity);
    void delete(Long id);
}
