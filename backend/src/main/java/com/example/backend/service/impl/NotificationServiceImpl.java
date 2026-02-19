package com.example.backend.service.impl;

import com.example.backend.dto.NotificationDTO;
import com.example.backend.exception.ResourceNotFoundException;
import com.example.backend.model.Notification;
import com.example.backend.repository.NotificationRepository;
import com.example.backend.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class NotificationServiceImpl implements NotificationService {

    private final NotificationRepository notificationRepository;

    @Override
    public NotificationDTO create(Long destinataireId, String type, String message, Long orderId, Long livreurId) {
        String title = switch (type) {
            case "ORDER_PROPOSED" -> "Nouvelle commande proposée";
            case "ORDER_ACCEPTED" -> "Commande acceptée";
            case "ORDER_REJECTED" -> "Commande refusée";
            case "ORDER_ASSIGNED" -> "Commande assignée";
            case "ORDER_STATUS" -> "Statut commande";
            default -> "Notification";
        };
        Notification notif = Notification.builder()
                .destinataireId(destinataireId)
                .title(title)
                .type(type)
                .message(message)
                .orderId(orderId)
                .livreurId(livreurId)
                .isRead(false)
                .build();
        notif = notificationRepository.save(notif);
        return toDTO(notif);
    }

    @Override
    @Transactional(readOnly = true)
    public List<NotificationDTO> getByDestinataire(Long destinataireId) {
        return notificationRepository.findByDestinataireIdOrderByCreatedAtDesc(destinataireId)
                .stream().map(this::toDTO).collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<NotificationDTO> getUnread(Long destinataireId) {
        return notificationRepository.findByDestinataireIdAndIsReadFalseOrderByCreatedAtDesc(destinataireId)
                .stream().map(this::toDTO).collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public long countUnread(Long destinataireId) {
        return notificationRepository.countByDestinataireIdAndIsReadFalse(destinataireId);
    }

    @Override
    public NotificationDTO markAsRead(Long notificationId) {
        Notification notif = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new ResourceNotFoundException("Notification", "id", notificationId));
        notif.setIsRead(true);
        notif = notificationRepository.save(notif);
        return toDTO(notif);
    }

    @Override
    public void markAllAsRead(Long destinataireId) {
        List<Notification> unread = notificationRepository
                .findByDestinataireIdAndIsReadFalseOrderByCreatedAtDesc(destinataireId);
        for (Notification n : unread) {
            n.setIsRead(true);
        }
        notificationRepository.saveAll(unread);
    }

    private NotificationDTO toDTO(Notification n) {
        return NotificationDTO.builder()
                .id(n.getId())
                .destinataireId(n.getDestinataireId())
                .title(n.getTitle())
                .type(n.getType())
                .message(n.getMessage())
                .orderId(n.getOrderId())
                .livreurId(n.getLivreurId())
                .isRead(n.getIsRead())
                .createdAt(n.getCreatedAt())
                .build();
    }
}
