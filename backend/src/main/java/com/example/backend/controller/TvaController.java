package com.example.backend.controller;

import com.example.backend.dto.TvaDTO;
import com.example.backend.service.TvaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/tva")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class TvaController {
    
    private final TvaService tvaService;
    
    @GetMapping
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<List<TvaDTO>> getAll() {
        return ResponseEntity.ok(tvaService.findAll());
    }
    
    @GetMapping("/actifs")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<List<TvaDTO>> getAllActive() {
        return ResponseEntity.ok(tvaService.findAllActive());
    }
    
    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<TvaDTO> getById(@PathVariable Long id) {
        return ResponseEntity.ok(tvaService.findById(id));
    }
    
    @GetMapping("/code/{code}")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<TvaDTO> getByCode(@PathVariable String code) {
        return ResponseEntity.ok(tvaService.findByCode(code));
    }
    
    @PostMapping
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<TvaDTO> create(@Valid @RequestBody TvaDTO tvaDTO) {
        TvaDTO created = tvaService.create(tvaDTO);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }
    
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<TvaDTO> update(@PathVariable Long id, @Valid @RequestBody TvaDTO tvaDTO) {
        return ResponseEntity.ok(tvaService.update(id, tvaDTO));
    }
    
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        tvaService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
