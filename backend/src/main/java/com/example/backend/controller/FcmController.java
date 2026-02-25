package com.example.backend.controller;

import com.example.backend.service.FcmService;
import com.example.backend.service.SecurityService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/fcm")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class FcmController {

    private final FcmService fcmService;
    private final SecurityService securityService;

    /**
     * Register or update the FCM device token for the current user.
     * Called by the Flutter app after obtaining the FCM token.
     * Body: { "token": "fcm_device_token_here" }
     */
    @PostMapping("/token")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<Map<String, String>> registerToken(@RequestBody Map<String, String> body) {
        Long userId = securityService.getCurrentUserId();
        String token = body.get("token");

        if (token == null || token.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Token is required"));
        }

        fcmService.registerToken(userId, token);
        return ResponseEntity.ok(Map.of("message", "FCM token registered successfully"));
    }

    /**
     * Remove the FCM token for the current user (e.g. on logout).
     */
    @DeleteMapping("/token")
    @PreAuthorize("hasAnyRole('GERANT', 'LIVREUR')")
    public ResponseEntity<Map<String, String>> removeToken() {
        Long userId = securityService.getCurrentUserId();
        fcmService.removeToken(userId);
        return ResponseEntity.ok(Map.of("message", "FCM token removed successfully"));
    }
}
