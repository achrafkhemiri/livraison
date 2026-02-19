package com.example.backend.controller;

import com.example.backend.dto.OrderDTO;
import com.example.backend.service.OrderService;
import com.example.backend.service.SecurityService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class OrderController {
    
    private final OrderService orderService;
    private final SecurityService securityService;
    
    @GetMapping
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<List<OrderDTO>> getAll() {
        Long societeId = securityService.getCurrentUserSocieteId();
        if (societeId != null) {
            return ResponseEntity.ok(orderService.findBySocieteId(societeId));
        }
        return ResponseEntity.ok(orderService.findAll());
    }
    
    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<OrderDTO> getById(@PathVariable Long id) {
        return ResponseEntity.ok(orderService.findById(id));
    }
    
    @GetMapping("/numero/{numero}")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<OrderDTO> getByNumero(@PathVariable String numero) {
        return ResponseEntity.ok(orderService.findByNumero(numero));
    }
    
    @GetMapping("/user/{userId}")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<List<OrderDTO>> getByUserId(@PathVariable Long userId) {
        return ResponseEntity.ok(orderService.findByUserId(userId));
    }
    
    // Endpoint for livreur to get unassigned pending orders (MUST be before /livreur/{livreurId})
    @GetMapping("/livreur/pending")
    @PreAuthorize("hasRole('LIVREUR')")
    public ResponseEntity<List<OrderDTO>> getPendingOrdersForLivreurAuth() {
        Long currentUserId = securityService.getCurrentUserId();
        return ResponseEntity.ok(orderService.findPendingOrdersForLivreur(currentUserId));
    }
    
    @GetMapping("/livreur/{livreurId}")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<List<OrderDTO>> getByLivreurId(@PathVariable Long livreurId) {
        return ResponseEntity.ok(orderService.findByLivreurId(livreurId));
    }
    
    @GetMapping("/livreur/{livreurId}/pending")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<List<OrderDTO>> getPendingOrdersForLivreur(@PathVariable Long livreurId) {
        return ResponseEntity.ok(orderService.findPendingOrdersForLivreur(livreurId));
    }
    
    @GetMapping("/status/{status}")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<List<OrderDTO>> getByStatus(@PathVariable String status) {
        return ResponseEntity.ok(orderService.findByStatus(status));
    }
    
    @GetMapping("/depot/{depotId}")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<List<OrderDTO>> getByDepotId(@PathVariable Long depotId) {
        return ResponseEntity.ok(orderService.findByDepotId(depotId));
    }
    
    @PostMapping
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<OrderDTO> create(@Valid @RequestBody OrderDTO orderDTO) {
        // Set societeId from current user if not provided
        if (orderDTO.getSocieteId() == null) {
            orderDTO.setSocieteId(securityService.getCurrentUserSocieteId());
        }
        OrderDTO created = orderService.create(orderDTO);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }
    
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<OrderDTO> update(@PathVariable Long id, @Valid @RequestBody OrderDTO orderDTO) {
        return ResponseEntity.ok(orderService.update(id, orderDTO));
    }
    
    @PatchMapping("/{id}/status")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<OrderDTO> updateStatus(@PathVariable Long id, @RequestParam String status) {
        return ResponseEntity.ok(orderService.updateStatus(id, status));
    }
    
    @PatchMapping("/{id}/assign/{livreurId}")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<OrderDTO> assignLivreur(@PathVariable Long id, @PathVariable Long livreurId) {
        return ResponseEntity.ok(orderService.assignLivreur(id, livreurId));
    }
    
    @PatchMapping("/{id}/accept")
    @PreAuthorize("hasRole('LIVREUR')")
    public ResponseEntity<OrderDTO> acceptAssignment(@PathVariable Long id) {
        Long currentUserId = securityService.getCurrentUserId();
        return ResponseEntity.ok(orderService.acceptAssignment(id, currentUserId));
    }
    
    @PatchMapping("/{id}/reject")
    @PreAuthorize("hasRole('LIVREUR')")
    public ResponseEntity<OrderDTO> rejectAssignment(@PathVariable Long id) {
        Long currentUserId = securityService.getCurrentUserId();
        return ResponseEntity.ok(orderService.rejectAssignment(id, currentUserId));
    }
    
    @GetMapping("/proposed")
    @PreAuthorize("hasRole('LIVREUR')")
    public ResponseEntity<List<OrderDTO>> getProposedOrders() {
        Long currentUserId = securityService.getCurrentUserId();
        return ResponseEntity.ok(orderService.findProposedOrdersForLivreur(currentUserId));
    }
    
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('GERANT')")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        orderService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
