package com.example.backend.service;

/**
 * Service for sending Firebase Cloud Messaging (FCM) push notifications.
 */
public interface FcmService {

    /**
     * Send a push notification to a specific user by their Utilisateur ID.
     *
     * @param userId  the Utilisateur ID
     * @param title   notification title
     * @param body    notification body/message
     * @param orderId optional related order ID (can be null)
     */
    void sendToUser(Long userId, String title, String body, Long orderId);

    /**
     * Register or update the FCM token for a user.
     *
     * @param userId   the Utilisateur ID
     * @param fcmToken the FCM device token
     */
    void registerToken(Long userId, String fcmToken);

    /**
     * Remove the FCM token for a user (e.g. on logout).
     *
     * @param userId the Utilisateur ID
     */
    void removeToken(Long userId);
}
