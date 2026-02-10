package com.example.backend.controller;

import com.example.backend.dto.SocieteDTO;
import com.example.backend.service.SocieteService;
import com.example.backend.service.SecurityService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/societes")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class SocieteController {
    
    private final SocieteService societeService;
    private final SecurityService securityService;
    
    @GetMapping
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<List<SocieteDTO>> getAll() {
        // Le gérant ne voit que sa propre société
        Long societeId = securityService.getCurrentUserSocieteId();
        if (societeId != null) {
            SocieteDTO societe = societeService.findById(societeId);
            return ResponseEntity.ok(List.of(societe));
        }
        return ResponseEntity.ok(societeService.findAll());
    }
    
    @GetMapping("/me")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<SocieteDTO> getMySociete() {
        Long societeId = securityService.getCurrentUserSocieteId();
        if (societeId != null) {
            return ResponseEntity.ok(societeService.findById(societeId));
        }
        return ResponseEntity.notFound().build();
    }
    
    @GetMapping("/{id}")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<SocieteDTO> getById(@PathVariable Long id) {
        return ResponseEntity.ok(societeService.findById(id));
    }
    
    @PostMapping
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<SocieteDTO> create(@Valid @RequestBody SocieteDTO societeDTO) {
        SocieteDTO created = societeService.create(societeDTO);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }
    
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<SocieteDTO> update(@PathVariable Long id, @Valid @RequestBody SocieteDTO societeDTO) {
        return ResponseEntity.ok(societeService.update(id, societeDTO));
    }
    
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        societeService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
