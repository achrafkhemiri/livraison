package com.example.backend.dto;

import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CollectedItemDTO {
    private Long produitId;
    private Integer quantity;
}
