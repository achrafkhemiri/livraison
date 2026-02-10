package com.example.backend.controller;

import com.example.backend.dto.ProduitDTO;
import com.example.backend.service.ProduitService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/produits")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class ProduitController {
    
    private final ProduitService produitService;
    
    @GetMapping
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<List<ProduitDTO>> getAll() {
        return ResponseEntity.ok(produitService.findAll());
    }
    
    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<ProduitDTO> getById(@PathVariable Long id) {
        return ResponseEntity.ok(produitService.findById(id));
    }
    
    @GetMapping("/reference/{reference}")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<ProduitDTO> getByReference(@PathVariable String reference) {
        return ResponseEntity.ok(produitService.findByReference(reference));
    }
    
    @PostMapping
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<ProduitDTO> create(@Valid @RequestBody ProduitDTO produitDTO) {
        ProduitDTO created = produitService.create(produitDTO);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }
    
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<ProduitDTO> update(@PathVariable Long id, @Valid @RequestBody ProduitDTO produitDTO) {
        return ResponseEntity.ok(produitService.update(id, produitDTO));
    }
    
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        produitService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
