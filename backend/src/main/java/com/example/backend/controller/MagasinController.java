package com.example.backend.controller;

import com.example.backend.dto.MagasinDTO;
import com.example.backend.service.MagasinService;
import com.example.backend.service.SecurityService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/magasins")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class MagasinController {
    
    private final MagasinService magasinService;
    private final SecurityService securityService;
    
    @GetMapping
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<List<MagasinDTO>> getAll() {
        Long societeId = securityService.getCurrentUserSocieteId();
        if (societeId != null) {
            return ResponseEntity.ok(magasinService.findBySocieteId(societeId));
        }
        return ResponseEntity.ok(magasinService.findAll());
    }
    
    @GetMapping("/actifs")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<List<MagasinDTO>> getAllActive() {
        Long societeId = securityService.getCurrentUserSocieteId();
        if (societeId != null) {
            return ResponseEntity.ok(magasinService.findBySocieteId(societeId));
        }
        return ResponseEntity.ok(magasinService.findAllActive());
    }
    
    @GetMapping("/societe/{societeId}")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<List<MagasinDTO>> getBySocieteId(@PathVariable Long societeId) {
        return ResponseEntity.ok(magasinService.findBySocieteId(societeId));
    }
    
    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<MagasinDTO> getById(@PathVariable Long id) {
        return ResponseEntity.ok(magasinService.findById(id));
    }
    
    @GetMapping("/nom/{nom}")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<MagasinDTO> getByNom(@PathVariable String nom) {
        return ResponseEntity.ok(magasinService.findByNom(nom));
    }
    
    @PostMapping
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<MagasinDTO> create(@Valid @RequestBody MagasinDTO magasinDTO) {
        MagasinDTO created = magasinService.create(magasinDTO);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }
    
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<MagasinDTO> update(@PathVariable Long id, @Valid @RequestBody MagasinDTO magasinDTO) {
        return ResponseEntity.ok(magasinService.update(id, magasinDTO));
    }
    
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        magasinService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
