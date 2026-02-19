package com.example.backend.repository;

import com.example.backend.model.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Long> {

    /** All notifications for a user, newest first */
    List<Notification> findByDestinataireIdOrderByCreatedAtDesc(Long destinataireId);

    /** Unread notifications for a user */
    List<Notification> findByDestinataireIdAndIsReadFalseOrderByCreatedAtDesc(Long destinataireId);

    /** Count unread */
    long countByDestinataireIdAndIsReadFalse(Long destinataireId);
}
