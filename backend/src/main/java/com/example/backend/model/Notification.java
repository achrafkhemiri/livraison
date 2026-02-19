package com.example.backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "notifications")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Who this notification is for (utilisateur.id — gerant or livreur) */
    @Column(name = "destinataire_id", nullable = false)
    private Long destinataireId;

    /** Short title for the notification */
    @Column(nullable = false)
    private String title;

    /** Type of notification */
    @Column(nullable = false, length = 50)
    private String type;
    // Types: ORDER_PROPOSED, ORDER_ACCEPTED, ORDER_REJECTED, ORDER_ASSIGNED, ORDER_STATUS

    @Column(nullable = false, columnDefinition = "TEXT")
    private String message;

    /** Related order, if any */
    @Column(name = "order_id")
    private Long orderId;

    /** Related livreur, if any */
    @Column(name = "livreur_id")
    private Long livreurId;

    @Column(name = "is_read", nullable = false)
    @Builder.Default
    private Boolean isRead = false;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
