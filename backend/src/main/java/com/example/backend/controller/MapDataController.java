package com.example.backend.controller;

import com.example.backend.dto.MapDataDTO;
import com.example.backend.dto.OrderDTO;
import com.example.backend.dto.ProductStockInfoDTO;
import com.example.backend.service.MapDataService;
import com.example.backend.service.OrderService;
import com.example.backend.service.SecurityService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class MapDataController {

    private final MapDataService mapDataService;
    private final OrderService orderService;
    private final SecurityService securityService;

    /**
     * Get map data for the current user's société:
     * - Société position
     * - Magasins positions
     * - Depots positions
     * - Livreurs last known positions
     */
    @GetMapping("/map-data")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<MapDataDTO> getMapData() {
        Long societeId = securityService.getCurrentUserSocieteId();
        if (societeId == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        return ResponseEntity.ok(mapDataService.getMapData(societeId));
    }

    /**
     * Get products with stock availability grouped by depot for the admin's société
     */
    @GetMapping("/products-stock")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<List<ProductStockInfoDTO>> getProductsWithStock() {
        Long societeId = securityService.getCurrentUserSocieteId();
        if (societeId == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        return ResponseEntity.ok(mapDataService.getProductsWithStockBySociete(societeId));
    }

    /**
     * Generate collection plan for an order
     * Determines which depots have the items and creates an optimized collection route
     */
    @PostMapping("/orders/{orderId}/collection-plan")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<Map<String, Object>> generateCollectionPlan(@PathVariable Long orderId) {
        Long societeId = securityService.getCurrentUserSocieteId();
        if (societeId == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        return ResponseEntity.ok(mapDataService.generateCollectionPlan(orderId, societeId));
    }

    /**
     * Mark an order as collected (all items picked up from depots)
     */
    @PatchMapping("/orders/{orderId}/collected")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<OrderDTO> markOrderCollected(@PathVariable Long orderId) {
        Long societeId = securityService.getCurrentUserSocieteId();
        if (societeId == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        return ResponseEntity.ok(orderService.markAsCollected(orderId));
    }
}
