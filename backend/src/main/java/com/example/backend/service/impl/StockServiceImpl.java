package com.example.backend.service.impl;

import com.example.backend.dto.StockDTO;
import com.example.backend.exception.InsufficientStockException;
import com.example.backend.exception.ResourceNotFoundException;
import com.example.backend.mapper.StockMapper;
import com.example.backend.model.Depot;
import com.example.backend.model.Produit;
import com.example.backend.model.Stock;
import com.example.backend.repository.DepotRepository;
import com.example.backend.repository.ProduitRepository;
import com.example.backend.repository.StockRepository;
import com.example.backend.service.StockService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class StockServiceImpl implements StockService {
    
    private final StockRepository stockRepository;
    private final ProduitRepository produitRepository;
    private final DepotRepository depotRepository;
    private final StockMapper stockMapper;
    
    @Override
    @Transactional(readOnly = true)
    public List<StockDTO> findAll() {
        return stockRepository.findAllWithProducts().stream()
                .map(stockMapper::toDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<StockDTO> findByDepotId(Long depotId) {
        return stockRepository.findByDepotId(depotId).stream()
                .map(stockMapper::toDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<StockDTO> findByProduitId(Long produitId) {
        return stockRepository.findByProduitId(produitId).stream()
                .map(stockMapper::toDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<StockDTO> findLowStock() {
        return stockRepository.findLowStock().stream()
                .map(stockMapper::toDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<StockDTO> findBySocieteId(Long societeId) {
        return stockRepository.findBySocieteId(societeId).stream()
                .map(stockMapper::toDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<StockDTO> findLowStockBySocieteId(Long societeId) {
        return stockRepository.findLowStockBySocieteId(societeId).stream()
                .map(stockMapper::toDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    @Transactional(readOnly = true)
    public StockDTO findById(Long id) {
        Stock stock = stockRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Stock", "id", id));
        return stockMapper.toDTO(stock);
    }
    
    @Override
    @Transactional(readOnly = true)
    public StockDTO findByProduitAndDepot(Long produitId, Long depotId) {
        Stock stock = stockRepository.findByProduitIdAndDepotId(produitId, depotId)
                .orElseThrow(() -> new ResourceNotFoundException("Stock pour ce produit dans ce dépôt non trouvé"));
        return stockMapper.toDTO(stock);
    }
    
    @Override
    public StockDTO create(StockDTO stockDTO) {
        Produit produit = produitRepository.findById(stockDTO.getProduitId())
                .orElseThrow(() -> new ResourceNotFoundException("Produit", "id", stockDTO.getProduitId()));
        
        Depot depot = depotRepository.findById(stockDTO.getDepotId())
                .orElseThrow(() -> new ResourceNotFoundException("Dépôt", "id", stockDTO.getDepotId()));
        
        Stock stock = stockMapper.toEntity(stockDTO);
        stock.setProduit(produit);
        stock.setDepot(depot);
        stock.setDerniereEntree(LocalDateTime.now());
        
        stock = stockRepository.save(stock);
        return stockMapper.toDTO(stock);
    }
    
    @Override
    public StockDTO update(Long id, StockDTO stockDTO) {
        Stock stock = stockRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Stock", "id", id));
        
        stockMapper.updateEntity(stock, stockDTO);
        stock = stockRepository.save(stock);
        return stockMapper.toDTO(stock);
    }
    
    @Override
    public StockDTO addStock(Long produitId, Long depotId, BigDecimal quantity) {
        Stock stock = stockRepository.findByProduitIdAndDepotId(produitId, depotId)
                .orElseGet(() -> {
                    Produit produit = produitRepository.findById(produitId)
                            .orElseThrow(() -> new ResourceNotFoundException("Produit", "id", produitId));
                    Depot depot = depotRepository.findById(depotId)
                            .orElseThrow(() -> new ResourceNotFoundException("Dépôt", "id", depotId));
                    
                    return Stock.builder()
                            .produit(produit)
                            .depot(depot)
                            .quantiteDisponible(BigDecimal.ZERO)
                            .quantiteReservee(BigDecimal.ZERO)
                            .build();
                });
        
        stock.setQuantiteDisponible(stock.getQuantiteDisponible().add(quantity));
        stock.setDerniereEntree(LocalDateTime.now());
        stock = stockRepository.save(stock);
        return stockMapper.toDTO(stock);
    }
    
    @Override
    public StockDTO removeStock(Long produitId, Long depotId, BigDecimal quantity) {
        Stock stock = stockRepository.findByProduitIdAndDepotId(produitId, depotId)
                .orElseThrow(() -> new ResourceNotFoundException("Stock pour ce produit dans ce dépôt non trouvé"));
        
        if (stock.getQuantiteDisponible().compareTo(quantity) < 0) {
            throw new InsufficientStockException(stock.getProduit().getDesignation(), depotId);
        }
        
        stock.setQuantiteDisponible(stock.getQuantiteDisponible().subtract(quantity));
        stock.setDerniereSortie(LocalDateTime.now());
        stock = stockRepository.save(stock);
        return stockMapper.toDTO(stock);
    }
    
    @Override
    public void delete(Long id) {
        if (!stockRepository.existsById(id)) {
            throw new ResourceNotFoundException("Stock", "id", id);
        }
        stockRepository.deleteById(id);
    }
}
