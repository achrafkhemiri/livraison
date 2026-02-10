package com.example.backend.controller;

import com.example.backend.dto.DepotDTO;
import com.example.backend.dto.StockDTO;
import com.example.backend.service.DepotService;
import com.example.backend.service.StockService;
import com.example.backend.service.SecurityService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/depots")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class DepotController {
    
    private final DepotService depotService;
    private final StockService stockService;
    private final SecurityService securityService;
    
    @GetMapping
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<List<DepotDTO>> getAll() {
        Long societeId = securityService.getCurrentUserSocieteId();
        if (societeId != null) {
            return ResponseEntity.ok(depotService.findBySocieteId(societeId));
        }
        return ResponseEntity.ok(depotService.findAll());
    }
    
    @GetMapping("/with-stocks")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<List<DepotDTO>> getAllWithStocks() {
        Long societeId = securityService.getCurrentUserSocieteId();
        List<DepotDTO> depots;
        if (societeId != null) {
            depots = depotService.findBySocieteId(societeId);
        } else {
            depots = depotService.findAll();
        }
        // Add stocks to each depot
        for (DepotDTO depot : depots) {
            List<StockDTO> stocks = stockService.findByDepotId(depot.getId());
            depot.setStocks(stocks);
        }
        return ResponseEntity.ok(depots);
    }
    
    @GetMapping("/actifs")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<List<DepotDTO>> getAllActive() {
        Long societeId = securityService.getCurrentUserSocieteId();
        if (societeId != null) {
            return ResponseEntity.ok(depotService.findActiveBySocieteId(societeId));
        }
        return ResponseEntity.ok(depotService.findAllActive());
    }
    
    @GetMapping("/magasin/{magasinId}")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<List<DepotDTO>> getByMagasinId(@PathVariable Long magasinId) {
        return ResponseEntity.ok(depotService.findByMagasinId(magasinId));
    }
    
    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<DepotDTO> getById(@PathVariable Long id) {
        return ResponseEntity.ok(depotService.findById(id));
    }
    
    @GetMapping("/code/{code}")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<DepotDTO> getByCode(@PathVariable String code) {
        return ResponseEntity.ok(depotService.findByCode(code));
    }
    
    @PostMapping
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<DepotDTO> create(@Valid @RequestBody DepotDTO depotDTO) {
        DepotDTO created = depotService.create(depotDTO);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }
    
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<DepotDTO> update(@PathVariable Long id, @Valid @RequestBody DepotDTO depotDTO) {
        return ResponseEntity.ok(depotService.update(id, depotDTO));
    }
    
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        depotService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
