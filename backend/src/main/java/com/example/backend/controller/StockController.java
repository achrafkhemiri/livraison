package com.example.backend.controller;

import com.example.backend.dto.StockDTO;
import com.example.backend.service.StockService;
import com.example.backend.service.SecurityService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;

@RestController
@RequestMapping("/api/stocks")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class StockController {
    
    private final StockService stockService;
    private final SecurityService securityService;
    
    @GetMapping
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<List<StockDTO>> getAll() {
        Long societeId = securityService.getCurrentUserSocieteId();
        if (societeId != null) {
            return ResponseEntity.ok(stockService.findBySocieteId(societeId));
        }
        return ResponseEntity.ok(stockService.findAll());
    }
    
    @GetMapping("/depot/{depotId}")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<List<StockDTO>> getByDepotId(@PathVariable Long depotId) {
        return ResponseEntity.ok(stockService.findByDepotId(depotId));
    }
    
    @GetMapping("/produit/{produitId}")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<List<StockDTO>> getByProduitId(@PathVariable Long produitId) {
        return ResponseEntity.ok(stockService.findByProduitId(produitId));
    }
    
    @GetMapping("/low")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<List<StockDTO>> getLowStock() {
        Long societeId = securityService.getCurrentUserSocieteId();
        if (societeId != null) {
            return ResponseEntity.ok(stockService.findLowStockBySocieteId(societeId));
        }
        return ResponseEntity.ok(stockService.findLowStock());
    }
    
    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<StockDTO> getById(@PathVariable Long id) {
        return ResponseEntity.ok(stockService.findById(id));
    }
    
    @GetMapping("/produit/{produitId}/depot/{depotId}")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<StockDTO> getByProduitAndDepot(@PathVariable Long produitId, @PathVariable Long depotId) {
        return ResponseEntity.ok(stockService.findByProduitAndDepot(produitId, depotId));
    }
    
    @PostMapping
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<StockDTO> create(@Valid @RequestBody StockDTO stockDTO) {
        StockDTO created = stockService.create(stockDTO);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }
    
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<StockDTO> update(@PathVariable Long id, @Valid @RequestBody StockDTO stockDTO) {
        return ResponseEntity.ok(stockService.update(id, stockDTO));
    }
    
    @PostMapping("/produit/{produitId}/depot/{depotId}/add")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<StockDTO> addStock(
            @PathVariable Long produitId, 
            @PathVariable Long depotId, 
            @RequestParam BigDecimal quantity) {
        return ResponseEntity.ok(stockService.addStock(produitId, depotId, quantity));
    }
    
    @PostMapping("/produit/{produitId}/depot/{depotId}/remove")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<StockDTO> removeStock(
            @PathVariable Long produitId, 
            @PathVariable Long depotId, 
            @RequestParam BigDecimal quantity) {
        return ResponseEntity.ok(stockService.removeStock(produitId, depotId, quantity));
    }
    
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        stockService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
