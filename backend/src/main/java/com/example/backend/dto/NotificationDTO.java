package com.example.backend.dto;

import lombok.*;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NotificationDTO {
    private Long id;
    private Long destinataireId;
    private String title;
    private String type;
    private String message;
    private Long orderId;
    private Long livreurId;
    private Boolean isRead;
    private LocalDateTime createdAt;
}
