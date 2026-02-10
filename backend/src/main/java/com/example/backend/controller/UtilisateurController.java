package com.example.backend.controller;

import com.example.backend.dto.CreateUtilisateurDTO;
import com.example.backend.dto.UtilisateurDTO;
import com.example.backend.service.UtilisateurService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/utilisateurs")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class UtilisateurController {
    
    private final UtilisateurService utilisateurService;
    
    @GetMapping
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<List<UtilisateurDTO>> getAll() {
        return ResponseEntity.ok(utilisateurService.findAll());
    }
    
    @GetMapping("/actifs")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<List<UtilisateurDTO>> getAllActive() {
        return ResponseEntity.ok(utilisateurService.findAllActive());
    }
    
    @GetMapping("/livreurs")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<List<UtilisateurDTO>> getAllLivreurs() {
        return ResponseEntity.ok(utilisateurService.findAllLivreurs());
    }
    
    @GetMapping("/gerants")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<List<UtilisateurDTO>> getAllGerants() {
        return ResponseEntity.ok(utilisateurService.findAllGerants());
    }
    
    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<UtilisateurDTO> getById(@PathVariable Long id) {
        return ResponseEntity.ok(utilisateurService.findById(id));
    }
    
    @PostMapping
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<UtilisateurDTO> create(@Valid @RequestBody CreateUtilisateurDTO createDTO) {
        UtilisateurDTO created = utilisateurService.create(createDTO);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }
    
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<UtilisateurDTO> update(@PathVariable Long id, @Valid @RequestBody UtilisateurDTO utilisateurDTO) {
        return ResponseEntity.ok(utilisateurService.update(id, utilisateurDTO));
    }
    
    @PatchMapping("/{id}/password")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<Void> updatePassword(@PathVariable Long id, @RequestBody Map<String, String> request) {
        utilisateurService.updatePassword(id, request.get("password"));
        return ResponseEntity.ok().build();
    }
    
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        utilisateurService.delete(id);
        return ResponseEntity.noContent().build();
    }
    
    @PatchMapping("/{id}/position")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<UtilisateurDTO> updatePosition(
            @PathVariable Long id,
            @RequestParam Double latitude,
            @RequestParam Double longitude) {
        return ResponseEntity.ok(utilisateurService.updatePosition(id, latitude, longitude));
    }
    
    @GetMapping("/livreurs/positions")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<List<UtilisateurDTO>> getLivreursPositions() {
        return ResponseEntity.ok(utilisateurService.findAllLivreursWithPositions());
    }
}
