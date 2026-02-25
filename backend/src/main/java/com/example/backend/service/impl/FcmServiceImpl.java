package com.example.backend.service.impl;

import com.example.backend.repository.UtilisateurRepository;
import com.example.backend.service.FcmService;
import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import com.google.firebase.messaging.AndroidConfig;
import com.google.firebase.messaging.AndroidNotification;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
public class FcmServiceImpl implements FcmService {

    private final UtilisateurRepository utilisateurRepository;

    @Override
    public void sendToUser(Long userId, String title, String body, Long orderId) {
        // Check if Firebase is initialized
        if (FirebaseApp.getApps().isEmpty()) {
            log.warn("Firebase not initialized — skipping push notification for user {}", userId);
            return;
        }

        utilisateurRepository.findById(userId).ifPresentOrElse(user -> {
            String token = user.getFcmToken();
            if (token == null || token.isBlank()) {
                log.debug("No FCM token for user {} — skipping push", userId);
                return;
            }

            try {
                Message.Builder messageBuilder = Message.builder()
                        .setToken(token)
                        .setNotification(Notification.builder()
                                .setTitle(title)
                                .setBody(body)
                                .build())
                        .setAndroidConfig(AndroidConfig.builder()
                                .setPriority(AndroidConfig.Priority.HIGH)
                                .setNotification(AndroidNotification.builder()
                                        .setSound("default")
                                        .setChannelId("smart_delivery_notifications")
                                        .build())
                                .build())
                        // Custom data payload for the Flutter app
                        .putData("type", "notification")
                        .putData("title", title)
                        .putData("body", body);

                if (orderId != null) {
                    messageBuilder.putData("orderId", orderId.toString());
                }

                String response = FirebaseMessaging.getInstance().send(messageBuilder.build());
                log.info("FCM push sent to user {} — messageId: {}", userId, response);

            } catch (Exception e) {
                log.error("Failed to send FCM push to user {}: {}", userId, e.getMessage());
                // If token is invalid, clear it
                if (e.getMessage() != null && (e.getMessage().contains("UNREGISTERED") 
                        || e.getMessage().contains("INVALID_ARGUMENT"))) {
                    log.info("Clearing invalid FCM token for user {}", userId);
                    user.setFcmToken(null);
                    utilisateurRepository.save(user);
                }
            }
        }, () -> log.warn("User {} not found — cannot send push", userId));
    }

    @Override
    @Transactional
    public void registerToken(Long userId, String fcmToken) {
        utilisateurRepository.findById(userId).ifPresent(user -> {
            user.setFcmToken(fcmToken);
            utilisateurRepository.save(user);
            log.info("FCM token registered for user {}", userId);
        });
    }

    @Override
    @Transactional
    public void removeToken(Long userId) {
        utilisateurRepository.findById(userId).ifPresent(user -> {
            user.setFcmToken(null);
            utilisateurRepository.save(user);
            log.info("FCM token removed for user {}", userId);
        });
    }
}
