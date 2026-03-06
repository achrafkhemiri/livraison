package com.example.backend.controller;

import com.example.backend.dto.CommissionConfigDTO;
import com.example.backend.dto.CommissionPaiementDTO;
import com.example.backend.dto.LivreurCommissionSummaryDTO;
import com.example.backend.dto.PageResponse;
import com.example.backend.service.CommissionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;

@RestController
@RequestMapping("/api/commissions")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class CommissionController {

    private final CommissionService commissionService;

    // ═══════════════════════════════════════════════════════
    //  Commission Config endpoints
    // ═══════════════════════════════════════════════════════

    @PostMapping("/configs")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<CommissionConfigDTO> createConfig(@RequestBody CommissionConfigDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(commissionService.createConfig(dto));
    }

    @PutMapping("/configs/{id}")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<CommissionConfigDTO> updateConfig(@PathVariable Long id, @RequestBody CommissionConfigDTO dto) {
        return ResponseEntity.ok(commissionService.updateConfig(id, dto));
    }

    @GetMapping("/configs/{id}")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<CommissionConfigDTO> getConfigById(@PathVariable Long id) {
        return ResponseEntity.ok(commissionService.getConfigById(id));
    }

    @GetMapping("/configs/livreur/{livreurId}")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<CommissionConfigDTO> getActiveConfigByLivreur(@PathVariable Long livreurId) {
        CommissionConfigDTO config = commissionService.getActiveConfigByLivreurId(livreurId);
        if (config == null) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.ok(config);
    }

    @GetMapping("/configs/livreur/{livreurId}/history")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<List<CommissionConfigDTO>> getConfigHistoryByLivreur(@PathVariable Long livreurId) {
        return ResponseEntity.ok(commissionService.getConfigsByLivreurId(livreurId));
    }

    @GetMapping("/configs/active")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<List<CommissionConfigDTO>> getAllActiveConfigs() {
        return ResponseEntity.ok(commissionService.getAllActiveConfigs());
    }

    @GetMapping("/configs/search")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<PageResponse<CommissionConfigDTO>> searchConfigs(
            @RequestParam(defaultValue = "") String search,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return ResponseEntity.ok(commissionService.searchConfigs(search, page, size));
    }

    @DeleteMapping("/configs/{id}")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<Void> deactivateConfig(@PathVariable Long id) {
        commissionService.deactivateConfig(id);
        return ResponseEntity.noContent().build();
    }

    // ═══════════════════════════════════════════════════════
    //  Commission Paiement endpoints
    // ═══════════════════════════════════════════════════════

    @PostMapping("/paiements/generate/{orderId}")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<CommissionPaiementDTO> generateCommission(
            @PathVariable Long orderId,
            @RequestParam(required = false) BigDecimal distanceKm) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(commissionService.generateCommission(orderId, distanceKm));
    }

    @GetMapping("/paiements")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<List<CommissionPaiementDTO>> getAllPaiements() {
        return ResponseEntity.ok(commissionService.getAllPaiements());
    }

    @GetMapping("/paiements/{id}")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<CommissionPaiementDTO> getPaiementById(@PathVariable Long id) {
        return ResponseEntity.ok(commissionService.getPaiementById(id));
    }

    @GetMapping("/paiements/order/{orderId}")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<CommissionPaiementDTO> getPaiementByOrder(@PathVariable Long orderId) {
        CommissionPaiementDTO paiement = commissionService.getPaiementByOrderId(orderId);
        if (paiement == null) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.ok(paiement);
    }

    @GetMapping("/paiements/livreur/{livreurId}")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<List<CommissionPaiementDTO>> getPaiementsByLivreur(@PathVariable Long livreurId) {
        return ResponseEntity.ok(commissionService.getPaiementsByLivreurId(livreurId));
    }

    @GetMapping("/paiements/search")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<PageResponse<CommissionPaiementDTO>> searchPaiements(
            @RequestParam(defaultValue = "") String search,
            @RequestParam(defaultValue = "") String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return ResponseEntity.ok(commissionService.searchPaiements(search, status, page, size));
    }

    @GetMapping("/paiements/livreur/{livreurId}/search")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<PageResponse<CommissionPaiementDTO>> searchPaiementsByLivreur(
            @PathVariable Long livreurId,
            @RequestParam(defaultValue = "") String search,
            @RequestParam(defaultValue = "") String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return ResponseEntity.ok(commissionService.searchPaiementsByLivreur(livreurId, search, status, page, size));
    }

    @PutMapping("/paiements/{id}/livreur-paye")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<CommissionPaiementDTO> markLivreurPaye(@PathVariable Long id) {
        return ResponseEntity.ok(commissionService.markLivreurPaye(id));
    }

    @PutMapping("/paiements/{id}/admin-valide")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<CommissionPaiementDTO> markAdminValide(@PathVariable Long id) {
        return ResponseEntity.ok(commissionService.markAdminValide(id));
    }

    @PutMapping("/paiements/{id}/unmark-livreur-paye")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<CommissionPaiementDTO> unmarkLivreurPaye(@PathVariable Long id) {
        return ResponseEntity.ok(commissionService.unmarkLivreurPaye(id));
    }

    @PutMapping("/paiements/{id}/unmark-admin-valide")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<CommissionPaiementDTO> unmarkAdminValide(@PathVariable Long id) {
        return ResponseEntity.ok(commissionService.unmarkAdminValide(id));
    }

    // ═══════════════════════════════════════════════════════
    //  Recalculate distances
    // ═══════════════════════════════════════════════════════

    @PutMapping("/paiements/recalculate-all")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<java.util.Map<String, Object>> recalculateAllDistances() {
        int updated = commissionService.recalculateAllDistances();
        return ResponseEntity.ok(java.util.Map.of("recalculated", updated));
    }

    // ═══════════════════════════════════════════════════════
    //  Summary endpoints
    // ═══════════════════════════════════════════════════════

    @GetMapping("/summary")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<List<LivreurCommissionSummaryDTO>> getAllSummaries() {
        return ResponseEntity.ok(commissionService.getAllLivreurSummaries());
    }

    @GetMapping("/summary/{livreurId}")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<LivreurCommissionSummaryDTO> getLivreurSummary(@PathVariable Long livreurId) {
        return ResponseEntity.ok(commissionService.getLivreurSummary(livreurId));
    }
}
