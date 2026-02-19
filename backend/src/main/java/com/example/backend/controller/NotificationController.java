package com.example.backend.controller;

import com.example.backend.dto.NotificationDTO;
import com.example.backend.service.NotificationService;
import com.example.backend.service.SecurityService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class NotificationController {

    private final NotificationService notificationService;
    private final SecurityService securityService;

    /** Get all notifications for the current user */
    @GetMapping
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<List<NotificationDTO>> getMyNotifications() {
        Long userId = securityService.getCurrentUserId();
        return ResponseEntity.ok(notificationService.getByDestinataire(userId));
    }

    /** Get unread notifications for the current user */
    @GetMapping("/unread")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<List<NotificationDTO>> getUnread() {
        Long userId = securityService.getCurrentUserId();
        return ResponseEntity.ok(notificationService.getUnread(userId));
    }

    /** Count unread notifications */
    @GetMapping("/unread/count")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<Map<String, Long>> countUnread() {
        Long userId = securityService.getCurrentUserId();
        long count = notificationService.countUnread(userId);
        return ResponseEntity.ok(Map.of("count", count));
    }

    /** Mark a specific notification as read */
    @PatchMapping("/{id}/read")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<NotificationDTO> markAsRead(@PathVariable Long id) {
        return ResponseEntity.ok(notificationService.markAsRead(id));
    }

    /** Mark all notifications as read */
    @PatchMapping("/read-all")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<Void> markAllAsRead() {
        Long userId = securityService.getCurrentUserId();
        notificationService.markAllAsRead(userId);
        return ResponseEntity.ok().build();
    }
}
