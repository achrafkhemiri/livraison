package com.example.backend.dto;

import lombok.*;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MapDataDTO {
    private SocieteMarker societe;
    private List<MagasinMarker> magasins;
    private List<DepotMarker> depots;
    private List<LivreurMarker> livreurs;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class SocieteMarker {
        private Long id;
        private String nom;
        private Double latitude;
        private Double longitude;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class MagasinMarker {
        private Long id;
        private String nom;
        private String adresse;
        private String ville;
        private Double latitude;
        private Double longitude;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class DepotMarker {
        private Long id;
        private String nom;
        private String code;
        private String adresse;
        private String ville;
        private Double latitude;
        private Double longitude;
        private Boolean actif;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class LivreurMarker {
        private Long id;
        private String nom;
        private String prenom;
        private Double latitude;
        private Double longitude;
        private String dernierePositionAt;
    }
}
