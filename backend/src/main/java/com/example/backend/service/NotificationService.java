package com.example.backend.service;

import com.example.backend.dto.NotificationDTO;
import java.util.List;

public interface NotificationService {
    NotificationDTO create(Long destinataireId, String type, String message, Long orderId, Long livreurId);
    List<NotificationDTO> getByDestinataire(Long destinataireId);
    List<NotificationDTO> getUnread(Long destinataireId);
    long countUnread(Long destinataireId);
    NotificationDTO markAsRead(Long notificationId);
    void markAllAsRead(Long destinataireId);
}
